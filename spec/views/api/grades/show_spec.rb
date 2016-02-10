# encoding: utf-8
require 'rails_spec_helper'

describe "api/grades/show" do
  before(:all) do
    world = World.create.with(:course, :assignment, :student, :grade)
    @grade = world.grade
  end

  it "responds with a grade" do
    render
    json = JSON.parse(response.body)
    expect(json["data"]["type"]).to eq("grades")
  end

  it "adds the attributes to the grade" do
    render
    json = JSON.parse(response.body)
    expect(json["data"]["attributes"]["id"]).to eq(@grade.id)
    expect(json["data"]["attributes"]["assignment_id"]).to eq(@grade.assignment_id)
    expect(json["data"]["attributes"]["student_id"]).to eq(@grade.student_id)
    expect(json["data"]["attributes"]["feedback"]).to eq(@grade.feedback)
    expect(json["data"]["attributes"]["status"]).to eq(@grade.status)
  end
end
