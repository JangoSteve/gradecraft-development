# encoding: utf-8
require 'spec_helper'

describe "students/syllabus" do

  before(:each) do
    clean_models
    @course = create(:course)
    @assignment_types = [create(:assignment_type, course: @course, max_value: 1000)]
    @assignment = create(:assignment, :assignment_type => @assignment_types[0])
    @course.assignments << @assignment
    @student = create(:user)
    @student.courses << @course
    view.stub(:current_course).and_return(@course)
    view.stub(:current_student).and_return(@student)
  end

  #TODO: once merged, move to assignments_spec
  # they are in here for now to avoid conflicts with the specs Max is currently writing.

  it "renders the points possible for the assignment" do
    render
    assert_select ".pagetitle", :count => 1
  end

end
