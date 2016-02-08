class CourseMembership < ActiveRecord::Base
  belongs_to :course, touch: true
  belongs_to :user, touch: true

  # adds logging helpers for rescued-out errors
  include ModelAddons::ImprovedLogging
  include ModelAddons::AdvancedRescue

  attr_accessible :auditing, :character_profile, :course, :course_id,
    :instructor_of_record, :user, :user_id, :role

  Role.all.each do |role|
    scope role.pluralize, ->(course) { where role: role }
    define_method("#{role}?") do
      self.role == role
    end
  end

  scope :auditing, -> { where( :auditing => true ) }
  scope :being_graded, -> { where( :auditing => false) }
  scope :instructors_of_record, -> { where(instructor_of_record: true) }
  scope :not_instructors_of_record, -> { where.not(instructor_of_record: true) }

  validates_presence_of :course, :user, :role

  validates :instructor_of_record, instructor_of_record: true

  def assign_role_from_lti(auth_hash)
    return unless auth_hash['extra'] && auth_hash['extra']['raw_info'] && auth_hash['extra']['raw_info']['roles']

    auth_hash['extra']['raw_info'].tap do |extra|

      case extra['roles'].downcase
      when /instructor/
        self.update_attribute(:role, 'professor')
      when /teachingassistant/
        self.update_attribute(:role, 'gsi')
      else
        self.update_attribute(:role, 'student')
        self.update_attribute(:instructor_of_record, false)
      end
    end
  end

  def recalculate_and_update_student_score
    update_attribute :score, recalculated_student_score
  end

  def recalculated_student_score
    assignment_type_totals_for_student +
    student_earned_badge_score +
    conditional_student_team_score
  end

  def staff?
    professor? || gsi? || admin?
  end

  private

  def assignment_type_totals_for_student
    rescue_with_logging 0 do
      course.assignment_types.collect do |assignment_type|
        assignment_type.visible_score_for_student(user)
      end.compact.sum || 0
    end
  end

  def student_earned_badge_score
    rescue_with_logging 0 do
      user.earned_badge_score_for_course(course_id) || 0
    end
  end

  def conditional_student_team_score
    include_team_score? ? student_team_score : 0
  end

  def student_team_score
    rescue_with_logging 0 do
      user.team_for_course(course_id).try(:score) || 0
    end
  end

  def include_team_score?
    course.add_team_score_to_student? and not course.team_score_average
  end
end
