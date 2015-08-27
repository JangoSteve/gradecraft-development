# encoding: utf-8
require 'spec_helper'
include CourseTerms

describe "assignment_types/new" do

  before(:all) do
    clean_models
    @course = create(:course)
    @assignment_type = AssignmentType.new
  end

  before(:each) do
    assign(:title, "Create a New Assignment Type")
    allow(view).to receive(:current_course).and_return(@course)
  end

  it "renders successfully" do
    render
    assert_select "h3", text: "Create a New Assignment Type", :count => 1
  end

  it "renders the breadcrumbs" do
    render
    assert_select ".content-nav", :count => 1
    assert_select ".breadcrumbs" do
      assert_select "a", :count => 3
    end
  end
end
