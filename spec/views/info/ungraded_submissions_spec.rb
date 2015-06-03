# encoding: utf-8
require 'spec_helper'
include CourseTerms

describe "info/ungraded_submissions" do

  before(:all) do
    clean_models
    @course = create(:course)
  end

  before(:each) do
    assign(:title, "Ungraded Assignment Submissions")
    view.stub(:current_course).and_return(@course)
  end

  it "renders successfully" do
    pending
    render
    assert_select "h3", text: "Ungraded Assignment Submissions", :count => 1
  end

  it "renders the breadcrumbs" do
    pending
    render
    assert_select ".content-nav", :count => 1
    assert_select ".breadcrumbs" do
      assert_select "a", :count => 2
    end
  end
end
