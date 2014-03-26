class NotificationMailer < ActionMailer::Base
  default from: 'mailer@gradecraft.com'

  def lti_error(user_info, course_info)
    @user = user_info
    @course = course_info
    mail(:to => 'cholma@umich.edu', :subject => 'Unknown LTI user/course') do |format|
      format.text
      format.html
    end
  end

  def kerberos_error(user_info)
    @user = user_info
    mail(:to => 'cholma@umich.edu', :subject => 'Unknown Kerberos user') do |format|
      format.text
      format.html
    end
  end

  def successful_submission(user_info, submission_info, course_info)
    @user = user_info
    @submission = submission_info
    @course = course_info
    mail(:to => "#{@user[:email]}", :subject => "#{@course[:courseno]} - #{@submission[:name]} Submitted") do |format|
      format.text
      format.html
    end
  end

  def grade_released(grade_id)
    @grade = Grade.find grade_id
    @user = @grade.student
    @course = @grade.course
    @assignment = @grade.assignment
    mail(:to => @user.email, :subject => "#{@course.courseno} - #{@assignment.name} Graded") do |format|
      format.text
      format.html
    end
  end

   def new_group(group_id)
    @group = Group.find group_id
    @course = @group.course
    @professor = @group.course.professor
    @assignment = @group.assignment
    mail(:to => @professor.email, :subject => "#{@course.courseno} - New Group to Review for the #{@assignment.name}") do |format|
      format.text
      format.html
    end
  end

  def earned_badge_awarded(earned_badge_id)
    @earned_badge = EarnedBadge.find earned_badge_id
    @user = @earned_badge.student
    @course = @earned_badge.course
    mail(:to => @user.email, :subject => "#{@course.courseno} - You've earned a new #{@course.badge_term}!") do |format|
      format.text
      format.html
    end
  end

end
