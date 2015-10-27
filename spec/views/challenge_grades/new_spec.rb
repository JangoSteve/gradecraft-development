# encoding: utf-8
require 'spec_helper'
include CourseTerms

describe "challenge_grades/new" do

  before(:all) do
    @course = create(:course)
    @challenge = create(:challenge, course: @course)
    @challenge_grade = ChallengeGrade.new
    @team = create(:team, course: @course)
  end

  before(:each) do
    assign(:title, "Grading #{@team.name}'s #{@challenge.name}")
    allow(view).to receive(:current_course).and_return(@course)
  end

  it "renders successfully" do
    render
    assert_select "h3", text: "Grading #{@team.name}'s #{@challenge.name}", :count => 1
  end

  it "renders the breadcrumbs" do
    render
    assert_select ".content-nav", :count => 1
    assert_select ".breadcrumbs" do
      assert_select "a", :count => 4
    end
  end
end
