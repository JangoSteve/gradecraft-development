module Services
  class CreatesNewUser

    attr_accessor :user, :attributes, :send_welcome_email

    def initialize(attributes, send_welcome_email=false)
      self.attributes = attributes
      self.send_welcome_email = send_welcome_email

      build_user
      generate_password
      generate_username
    end

    def create_and_activate
      user.transaction do
        save
        activate
        send_activation_needed_email
        send_welcome_email
      end
    end

    def build_user
      self.user = User.new attributes
    end

    def generate_password
      user.password = Sorcery::Model::TemporaryToken.generate_random_token unless user.internal?
    end


    def generate_username
      user.username = self.class.username_from_email(user.email) if user.username.blank?
      if user.internal?
        user.email = self.class.email_from_username(user.username) if user.email.blank?
        user.kerberos_uid = user.username
      end
    end

    def save
      raise(ActiveRecord::Rollback, "The user is invalid and cannot be saved") unless user.save
    end

    def activate
      user.activate! if user.internal?
    end

    def send_activation_needed_email
      UserMailer.activation_needed_email(user).deliver_now unless user.activated?
    end

    def send_welcome_email
      UserMailer.welcome_email(user).deliver_now if send_welcome_email && user.activated?
    end

    private

    def self.email_from_username(username)
      "#{username}@umich.edu"
    end

    def self.username_from_email(email)
      email.split(/@/).first
    end
  end
end
