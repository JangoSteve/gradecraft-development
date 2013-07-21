class Submission < ActiveRecord::Base
  attr_accessible :assignment, :assignment_id, :comment, :feedback, :group,
    :group_id, :attachment, :link, :student, :student_id, :creator,
    :creator_id, :text_feedback, :text_comment

  include Canable::Ables
  #userstamps! # adds creator and updater


  #has_attached_file :attachment

  belongs_to :assignment
  belongs_to :student, :class_name => 'User'
  belongs_to :creator, :class_name => 'User'
  belongs_to :group

  has_one :grade
  accepts_nested_attributes_for :grade

  #scope :ungraded

  validates_presence_of :assignment, :student

  scope :for_submittable, -> { where(submittable_id: submittable.id, submittable_type: submittable.class) }

  #Canable permissions
  def updatable_by?(user)
    if assignment.is_individual?
      submittable_id == user.id
    elsif assignment.has_teams?
      submittable_id == user.teams.first.id
    elsif assignment.has_groups?
      submittable_id == user.groups.first.id
    end
  end

  def destroyable_by?(user)
    if assignment.is_individual?
      submittable_id == user.id
    elsif assignment.has_teams?
      submittable_id == user.teams.first.id
    elsif assignment.has_groups?
      submittable_id == user.groups.first.id
    end
  end

  def viewable_by?(user)
    if assignment.is_individual?
      submittable_id == user.id
    elsif assignment.has_teams?
      submittable_id == user.teams.first.id
    elsif assignment.has_groups?
      submittable_id == user.groups.first.id
    end
  end

  #Grading status
  def status
    if grade
      "Graded"
    else
      "Ungraded"
    end
  end

  def ungraded
    status == "Ungraded"
  end
end
