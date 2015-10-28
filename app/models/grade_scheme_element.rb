class GradeSchemeElement < ActiveRecord::Base
  attr_accessible :letter, :low_range, :high_range, :level, :description, :course_id, :course, :updated_at

  belongs_to :course, touch: true

  validates_presence_of :low_range, :high_range
  validates_numericality_of :high_range, greater_than: Proc.new { |e| e.low_range.to_i }

  default_scope { order 'high_range DESC' }

  # Getting the name of the Grade Scheme Element - the Level if it's present, the Letter if not
  def name
    if level? && letter?
      "#{letter} / #{level}"
    elsif level?
      level
    elsif letter?
      letter
    else
      return nil
    end
  end

  # Checking to see if the grade elements overlap
  def overlap?(element)
    element.low_range <= high_range && element.high_range >= low_range
  end

  #Calculating the range that covers this element
  def range
    high_range.to_f - low_range.to_f
  end

  #Figuring out how many points a student has to earn the next level
  def points_to_next_level(student, course)
    #if high range, +1
    high_range - student.cached_score_for_course(course) + 1
  end

  #Calculating how far a student is through this level
  def progress_percent(student, course)
    ((student.cached_score_for_course(course) - low_range)/(range)) * 100
  end
end
