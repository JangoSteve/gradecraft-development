class Badge < ActiveRecord::Base

  attr_accessible :name, :description, :icon, :icon_cache, :visible, :can_earn_multiple_times, :value,
  :multiplier, :point_total, :earned_badges, :earned_badges_attributes, :score, :badge_file_ids,
  :badge_files_attributes, :badge_file, :position, :unlock_conditions, :unlock_conditions_attributes,
  :visible_when_locked, :course_id, :course

  # grade points available to the predictor from the assignment controller
  attr_accessor :prediction

  acts_as_list scope: :course

  mount_uploader :icon, BadgeIconUploader

  has_many :earned_badges, :dependent => :destroy
  has_many :predicted_earned_badges, :dependent => :destroy

  belongs_to :course, touch: true

  # Unlocks
  has_many :unlock_conditions, :as => :unlockable, :dependent => :destroy
  accepts_nested_attributes_for :unlock_conditions, allow_destroy: true, :reject_if => proc { |a| a['condition_type'].blank? || a['condition_id'].blank? }

  has_many :unlock_keys, :class_name => 'UnlockCondition', :foreign_key => :condition_id, :dependent => :destroy
  has_many :unlock_states, :as => :unlockable, :dependent => :destroy

  accepts_nested_attributes_for :earned_badges, allow_destroy: true, :reject_if => proc { |a| a['score'].blank? }

  has_many :badge_files, :dependent => :destroy
  accepts_nested_attributes_for :badge_files

  validates_presence_of :course, :name
  validates_numericality_of :point_total, :allow_blank => true

  scope :visible, -> { where(visible: true) }

  default_scope { order('position ASC') }

  def can_earn_multiple_times
    super || false
  end

  #indexed badges
  def awarded_count
    earned_badges.student_visible.count
  end

  # Checking to see if the badge has unlock conditions
  def is_unlockable?
    unlock_conditions.present?
  end

  def is_a_condition?
    unlock_keys.present?
  end

  def unlockable
    UnlockCondition.where(:condition_id => self.id, :condition_type => "Badge").first.unlockable
  end

  # Checks to see if a badge is available for a student to earn, specifically used to style a badge
  # as red/not in the predictor
  def is_unlocked_for_student?(student)
    if unlock_states.where(:student_id => student.id).present?
      unlock_states.where(:student_id => student.id).first.is_unlocked?
    elsif ! unlock_conditions.present?
      return true
    end
  end

  def check_unlock_status(student)
    goal = unlock_conditions.count
    count = count_unlock_conditions_met(student)
    if goal == count
      if unlock_states.where(:student_id => student.id).present?
        unlock_states.where(:student_id => student.id).first.unlocked = true
      else
        self.unlock_states.create(:student_id => student.id, :unlocked => true, :unlockable_id => self.id, :unlockable_type => "Assignment")
      end
    else
      return false
    end
  end

  def count_unlock_conditions_met(student)
    count = 0
    unlock_conditions.each do |condition|
      if condition.is_complete?(student)
        count += 1
      end
    end
    return count
  end

  def visible_for_student?(student)
    if is_unlockable?
      if visible_when_locked? || is_unlocked_for_student?(student)
        return true
      end
    else
      if visible?
        return true
      end
    end
  end

  def find_or_create_unlock_state(student)
    UnlockState.where(student: student, unlockable: self).first || UnlockState.create(student_id: student.id, unlockable_id: self.id, unlockable_type: "Badge")
  end

  #badges per role
  def earned_badges_by_student_id
    @earned_badges_by_student_id ||= earned_badges.group_by { |eb| [eb.student_id] }
  end

  def earned_badge_for_student(student)
    earned_badges_by_student_id[[student.id]].try(:first)
  end

  def find_or_create_predicted_earned_badge(student)
    PredictedEarnedBadge.where(student_id: student, badge: self).first || PredictedEarnedBadge.create(student_id: student.id, badge_id: self.id)
  end

  #Counting how many times a particular student has earned this badge
  def earned_badge_count_for_student(student)
     earned_badges.where(:student_id => student, :student_visible => true).count
  end

  def earned_badge_total_points(student)
    earned_badges.where(:student_id => student, :student_visible => true).pluck('score').sum
  end
end