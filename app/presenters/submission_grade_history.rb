module SubmissionGradeHistory
  def submission_grade_filtered_history(submission, grade)
    HistoryFilter.new(submission.historical_merge(grade))
      .remove("name" => "admin_notes")
      .remove("name" => "feedback_read")
      .remove("name" => "feedback_read_at")
      .remove("name" => "feedback_reviewed")
      .remove("name" => "feedback_reviewed_at")
      .remove("name" => "graded_at")
      .remove("name" => "graded_by_id")
      .remove("name" => "instructor_modified")
      .remove("name" => "score")
      .remove("name" => "status")
      .remove("name" => "submission_id")
      .remove("name" => "submitted_at")
      .remove("name" => "updated_at")
      .exclude { |changeset|
        changeset["object"] == "Grade" &&
          changeset["event"] == "create" &&
          !changeset.keys.include?("raw_score")
      }
      .changeset
  end
end