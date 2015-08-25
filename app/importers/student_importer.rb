require 'csv'

class StudentImporter
  attr_reader :successful, :unsuccessful
  attr_accessor :file

  def initialize(file)
    @file = file
    @successful = []
    @unsuccessful = []
  end

  def import(course=nil)
    if file
      CSV.foreach(file, headers: true, skip_blanks: true) do |row|
        team = find_or_create_team row, course
        if team && !team.valid?
          append_unsuccessful row, team.errors.full_messages.join(", ")
          next
        end

        user = create_user row, course

        if user.valid?
          team.students << user if team
          UserMailer.activation_needed_email(user).deliver_now
          successful << user
        else
          append_unsuccessful row, user.errors.full_messages.join(", ")
        end
      end
    end

    self
  end

  private

  def append_unsuccessful(row, errors)
    unsuccessful << { data: row.to_s, errors: errors }
  end

  def create_user(row, course)
    user = User.create do |u|
      u.first_name = row[0]
      u.last_name = row[1]
      u.username = row[2]
      u.email = row[3]
      u.password = generate_random_password
      u.course_memberships.build(course_id: course.id, role: "student") if course
    end
  end

  def find_or_create_team(row, course)
    name = row[4]
    return if name.blank?
    team = Team.find_by_course_and_name course.id, name
    team ||= Team.create course_id: course.id, name: name
  end

  def generate_random_password
    Sorcery::Model::TemporaryToken.generate_random_token
  end
end
