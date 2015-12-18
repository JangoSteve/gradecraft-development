class GroupNotifyPreview
  def group_notify
    group = Group.first
    NotificationMailer.group_notify group.id
  end
end