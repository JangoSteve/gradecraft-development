require 'active_record_spec_helper'
require './app/importers/grade_importer'

describe GradeImporter do
  describe "#import" do
    it "returns empty results when there is no file" do
      result = GradeImporter.new(nil).import
      expect(result.successful).to be_empty
      expect(result.unsuccessful).to be_empty
    end

    context "with a file" do
      let(:file) { fixture_file "grades.csv", "text/csv" }
      let(:course) { create :course }
      let(:assignment) { create :assignment, course: course }
      subject { GradeImporter.new(file.tempfile) }

      context "with a student not in the file" do
        let(:student) { create :user }
        before do
          create :course_membership, user_id: student.id, course_id: course.id,
              role: "student"
        end

        it "does not create a grade if the student does not exist" do
          expect { subject.import(course, assignment) }.to_not change { User.count }
        end

        it "is unsuccessful if the student does not exist" do
          result = subject.import(course, assignment)
          expect(result.unsuccessful.count).to eq 1
          expect(result.unsuccessful.first[:errors]).to eq "Student not found in course"
        end
      end

      context "with a student in the file" do
        let(:student) { create :user, email: "robert@example.com" }
        before do
          create :course_membership, user_id: student.id, course_id: course.id,
            role: "student"
        end

        it "creates the grade if it is not there" do
          result = subject.import(course, assignment)
          grade = Grade.last
          expect(grade.raw_score).to eq 4000
          expect(grade.feedback).to eq "You did great!"
          expect(grade.status).to eq "Graded"
          expect(grade.instructor_modified).to eq true
          expect(result.successful.count).to eq 1
          expect(result.successful.last).to eq grade
        end

        it "updates the grade if it is already there" do
          create :grade, assignment: assignment, student: student, raw_score: 1000
          subject.import(course, assignment)
          grade = Grade.last
          expect(grade.raw_score).to eq 4000
          expect(grade.feedback).to eq "You did great!"
        end

        xit "creates a grade for a student by unique name"
      end
    end
  end
end
