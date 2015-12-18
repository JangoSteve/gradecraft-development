class ResetPasswordEmailPreview
  def reset_password_email
    user = User.last
    UserMailer.reset_password_email user
  end
end