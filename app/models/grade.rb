class Grade < ActiveRecord::Base
  include Canable::Ables
  include Historical
  include MultipleFileAttributes
  include Sanitizable

  has_paper_trail ignore: [:predicted_score]

  attr_accessible :assignment, :assignments_attributes, :assignment_id,
    :assignment_type_id, :course_id, :feedback, :final_score, :grade_file,
    :grade_file_ids, :grade_files_attributes, :graded_by_id, :group, :group_id,
    :group_type, :instructor_modified, :pass_fail_status, :point_total,
    :predicted_score, :raw_score, :status, :student, :student_id, :submission,
    :_destroy, :submission_id, :task, :task_id, :team_id, :earned_badges,
    :earned_badges_attributes, :feedback_read, :feedback_read_at,
    :feedback_reviewed, :feedback_reviewed_at, :is_custom_value, :graded_at

  STATUSES= ["In Progress", "Graded", "Released"]

  # Note Pass and Fail use term_for in the views
  PASS_FAIL_STATUS = ["Pass", "Fail"]

  belongs_to :course, touch: true
  belongs_to :assignment, touch: true
  belongs_to :assignment_type, touch: true
  belongs_to :student, :class_name => 'User', touch: true
  belongs_to :team, touch: true
  belongs_to :submission
  belongs_to :task, touch: true # Optional
  belongs_to :group, :polymorphic => true, touch: true # Optional
  belongs_to :graded_by, class_name: 'User', touch: true

  has_many :earned_badges, :dependent => :destroy

  has_many :badges, :through => :earned_badges
  accepts_nested_attributes_for :earned_badges, :reject_if => proc { |a| (a['score'].blank?) }, :allow_destroy => true

  before_validation :cache_associations
  before_save :cache_point_total
  before_save :zero_points_for_pass_fail
  after_save :check_unlockables

  multiple_files :grade_files
  clean_html :feedback

  has_many :grade_files, :dependent => :destroy
  accepts_nested_attributes_for :grade_files

  validates_presence_of :assignment, :assignment_type, :course, :student
  validates :assignment_id, :uniqueness => {:scope => :student_id}

  delegate :name, :description, :due_at, :assignment_type, :course, :to => :assignment

  after_destroy :save_student_and_team_scores

  scope :completion, -> { where(order: "assignments.due_at ASC", :joins => :assignment) }
  scope :graded, -> { where('status = ?', 'Graded') }
  scope :in_progress, -> { where('status = ?', 'In Progress') }
  scope :released, -> { joins(:assignment).where("status = 'Released' OR (status = 'Graded' AND NOT assignments.release_necessary)") }
  scope :graded_or_released, -> { where("status = 'Graded' OR status = 'Released'")}
  scope :not_released, -> { joins(:assignment).where("status = 'Graded' AND assignments.release_necessary")}
  scope :instructor_modified, -> { where('instructor_modified = ?', true) }
  scope :positive, -> { where('score > 0')}
  scope :predicted_to_be_done, -> { where('predicted_score > 0')}
  scope :for_course, ->(course) { where(course_id: course.id) }
  scope :for_student, ->(student) { where(student_id: student.id) }
  scope :not_nil, -> { where.not(:score => nil)}

  # @mz todo: add specs
  scope :student_visible, -> { joins(:assignment).where(student_visible_sql) }

  #validates_numericality_of :raw_score, integer_only: true

  def self.find_or_create(assignment,student)
    Grade.where(student: student, assignment: assignment).first || Grade.create(student: student, assignment: assignment)
  end

  def self.find_or_create_grades(assignment,students)
    students.each do |student|
      find_or_create(assignment,student)
    end
    Grade.where(student_id: students.pluck(:id), assignment: assignment)
  end

  def add_grade_files(*files)
    files.each do |f|
      grade_files << GradeFile.create(file: f, filename: f.original_filename[0..49], grade_id: self.id)
    end
  end

  def feedback_read!
    update_attributes feedback_read: true, feedback_read_at: DateTime.now
  end

  def feedback_reviewed!
    update_attributes feedback_reviewed: true, feedback_reviewed_at: DateTime.now
  end

  def is_graded?
    self.status == 'Graded'
  end

  def in_progress?
    self.status == 'In Progress'
  end

  # Handle raw score attributes with commas (ex "300,000")
  def raw_score=(rs)
    if rs.class == String
      rs.gsub!(",","").to_i
    end
    write_attribute(:raw_score,rs)
  end

  def score
    if assignment_type.student_weightable?
      final_score || ((raw_score * assignment_weight).round if raw_score.present?)  || nil
    else
      final_score || raw_score || nil
    end
  end

  def predicted_score
    self[:predicted_score] || 0
  end

  def point_total
    assignment.point_total_for_student(student)
  end

  def assignment_weight
    assignment.weight_for_student(student)
  end

  def has_feedback?
    feedback != "" && feedback != nil
  end

  def is_released?
    status == 'Released'
  end

  def is_student_visible?
    is_released? || (is_graded? && ! assignment.release_necessary)
  end

  def status_is_graded_or_released?
    is_graded? || is_released?
  end
  alias_method :graded_or_released?, :status_is_graded_or_released?

  # @mz todo: port this over to cache_team_and_student_scores once
  # related methods have tests
  # want to make sure that nothing depends on the output of this method
  def save_student_and_team_scores
    self.student.improved_cache_course_score(self.course.id)
    if self.course.has_teams? && self.student.team_for_course(self.course).present?
      self.student.team_for_course(self.course).cache_score
    end
  end

  # @mz todo: add specs
  def cache_student_and_team_scores
    { cached_student_score: cache_student_score,
      cached_team_score: cache_team_score,
      student_id: self.student.try(:id),
      team_id: cached_student_team.try(:id)
    }.merge(cached_score_failure_information)
  end

  def check_unlockables
    if self.assignment.is_a_condition?
      unlock_conditions = UnlockCondition.where(:condition_id => self.assignment.id, :condition_type => "Assignment").each do |condition|
        if condition.unlockable_type == "Assignment"
          unlockable = Assignment.find(condition.unlockable_id)
          unlockable.check_unlock_status(student)
        elsif condition.unlockable_type == "Badge"
          unlockable = Badge.find(condition.unlockable_id)
          unlockable.check_unlock_status(student)
        end
      end
    end
  end

  private

  def self.student_visible_sql
    ["status = 'Released' OR (status = 'Graded' AND assignments.release_necessary = ?)", false]
  end

  def save_student
    if self.raw_score_changed? || self.status_changed?
      student.save
    end
  end

  def save_team
    if course.has_teams? && student.team_for_course(course).present?
      student.team_for_course(course).save
    end
  end

  def cache_point_total
    self.score = score
    self.point_total = point_total
  end

  def cache_associations
    self.student_id ||= submission.try(:student_id)
    self.task_id ||= submission.try(:task_id)
    self.assignment_id ||= submission.try(:assignment_id) || task.try(:assignment_id)
    self.assignment_type_id ||= assignment.try(:assignment_type_id)
    self.course_id ||= assignment.try(:course_id)
    #self.team_id ||= student.team_for_course(course).try(:id)
  end

  def zero_points_for_pass_fail
    if self.assignment.pass_fail?
      self.raw_score = 0
      self.final_score = 0
      self.point_total = 0

      # use 1 for pass, 0 for fail
      self.predicted_score = 1 if self.predicted_score > 1
    end
  end

  def duplicate_badge_for_grade
    if self.earned_badges.where(:badge_id => earned_badge.badge_id).persisted?
      errors.add("")
    end
  end

  def cached_student_team
    @team ||= student.team_for_course(course)
  end

  # @mz todo: add specs
  def cache_student_score
    @student = self.student
    @student_update_successful = @student.improved_cache_course_score(self.course.id)
  end

  # @mz todo: add specs, improve the syntax here
  def cache_team_score
    if course.has_teams? && student.team_for_course(course).present?
      @team = cached_student_team
      @team_update_successful = @team.update_revised_team_score
      @team_update_successful ? @team.score : false
    else
      nil
    end
  end

  def cached_score_failure_information
    failure_attrs = {}
    if course.has_teams? && student.team_for_course(course).present?
      unless @team_update_successful
        failure_attrs.merge! team: @team.attributes
      end

      unless @student_update_successful
        failure_attrs.merge! student: @student.attributes
      end

      unless @team_update_successful and @student_update_successful
        failure_attrs.merge! grade: self.attributes
      end
    end

    failure_attrs
  end

end
