class GroupStatusUpdatedPreview
  def group_status_updated
    group = Group.first
    NotificationMailer.group_status_updated group.id
  end
end