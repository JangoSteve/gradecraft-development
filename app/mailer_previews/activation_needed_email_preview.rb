class ActivationNeededEmailPreview
  def activation_needed_email
    user = User.last
    UserMailer.activation_needed_email user
  end
end