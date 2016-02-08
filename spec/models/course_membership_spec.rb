require "active_record_spec_helper"

describe CourseMembership do
  describe ".instructors_of_record" do
    it "returns all course memberships that are marked as instructors of record" do
      instructor_of_record = create :professor_course_membership, instructor_of_record: true
      non_instructor = create :professor_course_membership, instructor_of_record: false
      results = described_class.instructors_of_record

      expect(results).to include instructor_of_record
      expect(results).to_not include non_instructor
    end
  end
end
