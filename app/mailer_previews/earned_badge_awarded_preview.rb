class EarnedBadgeAwardedPreview
  def earned_badge_awarded
    earned_badge = EarnedBadge.last
    NotificationMailer.earned_badge_awarded earned_badge.id
  end
end
