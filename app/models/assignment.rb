class Assignment < ActiveRecord::Base
  has_many :grades, :dependent => :destroy
  accepts_nested_attributes_for :grades

  #belongs_to :grade_scheme
  #has_many :grade_scheme_elements, :through => :grade_scheme

  belongs_to :assignment_type
  accepts_nested_attributes_for :assignment_type

  has_many :weights, :class_name => 'AssignmentWeight'
  has_many :groups
  has_many :group_memberships, :through => :group_memberships
  has_many :users, :through => :grades
  has_one :rubric
  belongs_to :category
  has_many :tasks
  has_many :submissions, :through => :tasks
  belongs_to :course

  has_many :score_levels, :through => :assignment_type
  accepts_nested_attributes_for :score_levels, allow_destroy: true

  delegate :points_predictor_display, :mass_grade, :student_weightable?, :to => :assignment_type

  before_validation :set_course_id

  validates_presence_of :assignment_type, :name, :grade_scope

  attr_accessible :type, :name, :description, :point_total, :due_date,
    :created_at, :updated_at, :level, :present, :grades_attributes, :assignment_type,
    :assignment_type_id, :grade_scope, :visible, :grade_scheme_id, :required,
    :open_time, :has_assignment_submissions, :student_logged_button_text,
    :student_logged, :badge_set_id, :release_necessary,
    :score_levels_attributes, :open_date, :close_time, :course, :due_date

  scope :individual_assignment, -> { where grade_scope: "Individual" }
  scope :group_assignment, -> { where grade_scope: "Group" }
  scope :team_assignment, -> { where grade_scope: "Team" }

  scope :chronological, -> { order('due_date ASC') }

  scope :with_due_date, -> { where('assignments.due_date IS NOT NULL') }
  scope :future, -> { with_due_date.where('assignments.due_date >= ?', Date.today) }
  scope :past, -> { with_due_date.where('assignments.due_date < ?', Date.today) }

  scope :grading_done, -> { where assignment_grades.present? == 1 }

  #grades per role
  def grades_by_gradeable_id
    @grades_by_gradeable_id ||= grades.group_by { |g| [g.gradeable_type,g.gradeable_id] }
  end

  def grade_for_student(student)
    grades_by_gradeable_id[['User',student.id]].try(:first)
  end

  def grade_for_group(group, user)
    grades_by_gradeable_id[['Group',group.id]].try(:first)
  end

  def grade_for_whole_group(group)
    grades_by_gradeable_id[['Group',group.id]].try(:first)
  end

  def grade_for_team(team)
    grades_by_gradeable_id[['Team',team.id]].try(:first)
  end

  #submissions per role
  def submissions_by_submittable_id
    @submissions_by_submittable_id || submissions.group_by { |s| [s.submittable_type,s.submittable_id] }
  end

  def submission_for_student(student)
    submissions_by_submittable_id[['User',student.id]].try(:first)
  end


  def submission_for_group(group)
    submissions_by_submittable_id[['Group',group.id]].try(:first)
  end

  def submission_for_team(team)
    submissions_by_submittable_id[['Team',team.id]].try(:first)
  end

  def submissions_by_assignment_id
    @submissions_by_assignment_id ||= submissions.group_by(&:assignment_id)
  end

  def submissions_for_assignment(assignment)
    submissions_by_assignment_id[assignment.id].try(:first)
  end

  #Assignment grade data
  def assignment_grades
    Grade.where(:assignment_id => id)
  end

  def high_score
    assignment_grades.maximum(:raw_score)
  end

  def low_score
    assignment_grades.minimum(:raw_score)
  end

  def average
    assignment_grades.average(:raw_score).try(:round)
  end

  def type
    assignment_type.try(:name)
  end

  def release_necessary?
    release_necessary == true
  end

  def is_individual?
    !['Group','Team'].include? grade_scope
  end

  def has_groups?
    grade_scope=="Group"
  end

  def has_teams?
    grade_scope=="Team"
  end

  def point_total
    super || assignment_type.universal_point_value
  end

  def point_total_for_student(student)
    (point_total * weight_for_student(student)).to_i
  end

  def weight_for_student?(student)
    student_weightable? && weights_by_student_id[student.id] > 0
  end

  def weight_for_student(student)
    if weight_for_student?(student)
      weights_by_student_id[student.id]
    else
      course.default_assignment_weight
    end
  end

  def past?
    due_date != nil && due_date < Date.today
  end

  def future?
    due_date != nil && due_date >= Date.today
  end

  def soon?
    if due_date?
      Time.now <= due_date && due_date < (Time.now + 7.days)
    end
  end

  def fixed?
    points_predictor = "Fixed"
  end

  def has_submissions?
    has_submissions == true
  end

  def has_ungraded_submissions?
    has_submissions == true && submissions.try(:ungraded)
  end

  def slider?
    points_predictor = "Slider"
  end

  def select?
    points_predictor = "Select List"
  end

  def self_gradeable?
    student_logged == true
  end

  def is_required?
    required == true
  end

  def has_levels?
    assignment_type.levels == true
  end

  def mass_grade?
    assignment_type.mass_grade = true
  end

  def grade_checkboxes?
    assignment_type.mass_grade_type == "Checkbox"
  end

  def grade_select?
    assignment_type.mass_grade_type == "Select List"
  end

  def mass_grade?
    mass_grade == true
  end

  def grade_radio?
    assignment_type.mass_grade_type =="Radio Buttons"
  end

  def open?
    (open_date !=nil && open_date < Time.now) && (due_date != nil && due_date > Time.now)
  end

  def grade_level(grade)
    score_levels.each do |score_level|
      return score_level.name if grade.raw_score == score_level.value
    end
    nil
  end

  private

  def weights_by_student_id
    @weights_by_student_id ||= Hash.new { |h, k| h[k] = 0 }.tap do |weights_hash|
      weights.each do |weight|
        weights_hash[weight.student_id] = weight.weight
      end
    end
  end

  def set_course_id
    self.course_id = assignment_type.course_id
  end
end
