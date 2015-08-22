class EarnedBadge < ActiveRecord::Base
  attr_accessible :score, :feedback, :student, :badge, :student_id, :badge_id, :submission_id,
    :course_id, :assignment_id, :tier_id, :metric_id, :student_visible, :tier_badge_id, :grade, :_destroy, :course,
    :predicted_points, :status, :grade_id, :raw_score, :feedback, :is_custom_value

  STATUSES= ["Predicted", "Earned"]

  belongs_to :course
  belongs_to :badge
  belongs_to :student, :class_name => 'User', touch: true
  belongs_to :submission # Optional
  belongs_to :task # Optional
  belongs_to :grade # Optional
  belongs_to :group, :polymorphic => true # Optional
  has_many :badge_files, :through => :badge

  before_validation :cache_associations

  validates_presence_of :badge, :course, :student

  after_save :check_unlockables

  #Some badges can only be earned once - we check on award if that's the case
  validate :multiple_allowed

  delegate :name, :description, :icon, :to => :badge

  def self.score
    pluck('SUM(score)').first || 0
  end

  def self.scores_for_students
    group(:student_id).pluck('earned_badges.student_id, COALESCE(SUM(score), 0)')
  end

  def check_unlockables 
    if self.badge.is_a_condition?
      unlock_conditions = UnlockCondition.where(:condition_id => self.badge.id, :condition_type => "Badge").each do |condition|
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

  def cache_associations
    self.course_id ||= badge.try(:course_id)
    self.score ||= badge.try(:point_total)
  end

  def multiple_allowed
    if ! self.badge.can_earn_multiple_times? && self.badge.earned_badge_for_student(self.student)
      errors.add :weight, " Oops, they've already earned this #{course.badge_term.downcase}."
    end
  end

end
