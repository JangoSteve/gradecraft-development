class NotificationMailer < ApplicationMailer
  layout "mailers/notification_layout"

  def lti_error(user_data, course_data)
    @user_data = user_data
    @course_data = course_data
    mail(to: ADMIN_EMAIL, subject: 'Unknown LTI user/course') do |format|
      format.text
    end
  end

  def kerberos_error(kerberos_uid)
    @kerberos_uid = kerberos_uid
    mail(to: ADMIN_EMAIL, subject: 'Unknown Kerberos user') do |format|
      format.text
    end
  end

  def grade_export(course, user, csv_data)
    @course = course
    @user = user
    attachments["grade_export_#{course.id}.csv"] = {:mime_type => 'text/csv',:content => csv_data }
    mail(to: @user.email,
         bcc:ADMIN_EMAIL,
         subject: "Grade export for #{course.name} is attached") do |format|
      format.text
    end
  end

  def gradebook_export(course, user, export_type, csv_data)
    @course = course
    @user = user
    attachments["gradebook_export_#{course.id}.csv"] = {:mime_type => 'text/csv',:content => csv_data }
    @export_type = export_type
    mail(to:  @user.email,
         bcc: ADMIN_EMAIL,
         subject: "Gradebook export for #{@course.name} #{@export_type} is attached") do |format|
      format.text
    end
  end

  def successful_submission(submission_id)
    @submission = Submission.find submission_id
    @user = @submission.student
    @course = @submission.course
    @assignment = @submission.assignment
    mail(to: @user.email,
         subject: "#{@course.courseno} - #{@assignment.name} Submitted") do |format|
      format.text
      format.html
    end
  end

  def updated_submission(submission_id)
    @submission = Submission.find submission_id
    @user = @submission.student
    @course = @submission.course
    @assignment = @submission.assignment
    mail(to: @user.email,
      subject: "#{@course.courseno} - #{@assignment.name} Submission Updated") do |format|
      format.text
      format.html
    end
  end

  def new_submission(submission_id, professor)
    @submission = Submission.find submission_id
    @student = @submission.student
    @course = @submission.course
    @assignment = @submission.assignment
    @professor = professor
    mail(to: @professor.email, subject: "#{@course[:courseno]} - #{@assignment.name} - New Submission to Grade") do |format|
      format.text
    end
  end

  def revised_submission(submission_id, professor)
    @submission = Submission.find submission_id
    @student = @submission.student
    @course = @submission.course
    @assignment = @submission.assignment
    @professor = professor
    mail(to: @professor.email, subject: "#{@course[:courseno]} - #{@assignment.name} - Updated Submission to Grade") do |format|
      format.text
    end
  end

  def grade_released(grade_id)
    @grade = Grade.find grade_id
    @student = @grade.student
    @course = @grade.course
    @assignment = @grade.assignment
    mail(to: @student.email,
      subject: "#{@course.courseno} - #{@assignment.name} Graded") do |format|
      format.text
      format.html
    end
  end


  def earned_badge_awarded(earned_badge_id)
    @earned_badge = EarnedBadge.find earned_badge_id
    @student = @earned_badge.student
    @course = @earned_badge.course
    mail(to: @student.email,
      subject: "#{@course.courseno} - You've earned a new #{@course.badge_term}!") do |format|
      format.text
      format.html
    end
  end

  #  def group_created(group_id, professor)
  #    @group = Group.find group_id
  #    @course = @group.course
  #    @professor = professor
  #    mail(to: @professor.email, subject: "#{@course.courseno} - New Group to Review") do |format|
  #      format.text
  #    end
  #  end

  # these have been commented out in the group controller
  # def group_notify(group_id)
  #   @group = Group.find group_id
  #   @course = @group.course
  #   @group.students.each do |group_member|
  #     mail(to: group_member.email, subject: "#{@course.courseno} - New Group") do |format|
  #       @student = group_member
  #       format.text
  #     end
  #   end
  # end

  # def group_status_updated(group_id)
  #   @group = Group.find group_id
  #   @course = @group.course
  #   @group.students.each do |group_member|
  #     mail(to: group_member.email, subject: "#{@course.courseno} - Group #{@group.approved}") do |format|
  #       @student = group_member
  #       format.text
  #     end
  #   end
  # end
end
