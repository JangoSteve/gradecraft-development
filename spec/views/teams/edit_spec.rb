# encoding: utf-8
require 'rails_spec_helper'
include CourseTerms

describe "teams/edit" do

  before(:all) do
    @course = create(:course)
    @team = create(:team, course: @course)
  end

  before(:each) do
    assign(:title, "Editing #{@team.name}")
    allow(view).to receive(:current_course).and_return(@course)
  end

  it "renders successfully" do
    render
    assert_select "h3", text: "Editing #{@team.name}", :count => 1
  end

  it "renders the breadcrumbs" do
    render
    assert_select ".content-nav", :count => 1
    assert_select ".breadcrumbs" do
      assert_select "a", :count => 4
    end
  end
end

