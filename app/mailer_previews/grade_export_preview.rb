class GradeExportPreview
  def grade_export
    course = Course.first
    user = User.first
    csv_data = course.assignments.to_csv
    NotificationMailer.grade_export course, user, csv_data
  end
end