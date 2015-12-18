class EarnedBadgeAwardedPreview
  def earned_badge_awarded
    earned_badge = EarnedBadge.last
    student = earned_badge.student
    NotificationMailer.earned_badge_awarded earned_badge.id
  end
end
