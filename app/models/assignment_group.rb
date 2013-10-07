class AssignmentGroup < ActiveRecord::Base

  attr_accessible :assignment, :assignment_id, :group, :group_id

  belongs_to :assignment
  belongs_to :group

end