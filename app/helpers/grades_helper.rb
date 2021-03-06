module GradesHelper
  extend SubmissionsHelper

  def grading_status_count_for(course)
    unreleased_grades_count_for(course) +
      in_progress_grades_count_for(course) +
      ungraded_submissions_count_for(course)
  end

  def in_progress_grades_count_for(course)
    Rails.cache.fetch(in_progress_grades_count_cache_key(course)) do
      course.grades.in_progress.count
    end
  end

  def in_progress_grades_count_cache_key(course)
    # This cache key is busted when a grade is updated as a Grade touches a Course
    "#{course.cache_key}/in_progress_grades_count"
  end

  def unreleased_grades_count_for(course)
    Rails.cache.fetch(unreleased_grades_count_cache_key(course)) do
      course.grades.not_released.count
    end
  end

  def unreleased_grades_count_cache_key(course)
    # This cache key is busted when a grade is updated as a Grade touches a Course
    "#{course.cache_key}/unreleased_grades_count"
  end
end
