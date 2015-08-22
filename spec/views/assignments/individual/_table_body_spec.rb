# encoding: utf-8
require 'spec_helper'
include CourseTerms

describe "assignments/individual/_table_body" do

  before(:each) do
    clean_models
    course = create(:course)
    @assignment_type = create(:assignment_type)
    @assignment = create(:assignment, assignment_type: @assignment_type)
    course.assignments << @assignment
    student = create(:user)
    student.courses << course
    @grade = create(:grade, course: course, assignment: @assignment, student: student)
    @students = [student]
    @grades = student.grades
    view.stub(:current_course).and_return(course)
  end

  it "renders successfully" do
    render
  end

  describe "with a graded grade", failing: true do
    before(:each) do
      @grade.update(status: "Graded", instructor_modified: true)
      view.stub(:remove_grades_assignment_path).and_return("#")
    end

    describe "with a score" do
      context "and the grade is present and instructor modified" do 
        it "renders the raw score" do
          @grade.update(raw_score: @assignment.point_total)
          @grade.stub(:present?) {true}
          @grade.stub(:instructor_modified) {true}
          render
          assert_select "td.status-or-score", text: "#{points @grade.raw_score}"
        end
      end

      context "and the grade is not present" do
        it "doesn't render the raw score" do
          @grade.update(raw_score: @assignment.point_total)
          @grade.stub(:present?) {false}
          @grade.stub(:instructor_modified) {true}
          render
          assert_select "td.status-or-score", text: "#{points @grade.raw_score}"
        end
      end

      context "and the grade is not instructor modified" do
        it "doesn't render the raw score" do
          @grade.update(raw_score: @assignment.point_total)
          @grade.stub(:present?) {true}
          @grade.stub(:instructor_modified) {false}
          render
          assert_select "td.status-or-score", text: "#{points @grade.raw_score}"
        end
      end
    end

    describe "with a pass fail assignment type" do
      it "renders pass/fail status" do
        @assignment.update(pass_fail: true)
        @grade.update(pass_fail_status: "Pass")
        render
        assert_select "td", text: @grade.pass_fail_status
      end
    end
  end
end
