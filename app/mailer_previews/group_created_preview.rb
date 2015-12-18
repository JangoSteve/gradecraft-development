class GroupCreatedPreview
  def group_created
    group = Group.first
    professor = User.first
    NotificationMailer.group_created group.id, professor
  end
end