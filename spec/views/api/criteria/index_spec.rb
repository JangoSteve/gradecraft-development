# encoding: utf-8
require 'rails_spec_helper'

describe "api/criteria/index" do
  before(:all) do
    world = World.create.with(:course, :assignment, :rubric, :criterion)
    @criteria = [world.criterion]
  end

  it "responds with an array of criteria" do
    render
    json = JSON.parse(response.body)
    expect(json["data"].length).to eq(1)
  end

  it "adds the attributes to the criteria" do
    render
    json = JSON.parse(response.body)
    expect(json["data"][0]["attributes"]["id"]).to eq(@criteria[0].id)
    expect(json["data"][0]["attributes"]["name"]).to eq(@criteria[0].name)
    expect(json["data"][0]["attributes"]["description"]).to eq(@criteria[0].description)
    expect(json["data"][0]["attributes"]["max_points"]).to eq(@criteria[0].max_points)
    expect(json["data"][0]["attributes"]["order"]).to eq(@criteria[0].order)
  end

  it "adds the levels to the criteria attributes" do
    render
    json = JSON.parse(response.body)
    expect(json["data"][0]["attributes"]["levels"].count).to eq(@criteria[0].levels.count)
    expect(json["data"][0]["attributes"]["levels"][0]["id"]).to eq(@criteria[0].levels.first.id)
  end

  it "adds level badges to the level" do
    allow_any_instance_of(Level).to receive(:level_badges)
      .and_return [double(:level_badge, id: 123, level_id: 456, badge_id: 789)]
    render
    json = JSON.parse(response.body)
    expect(json["data"][0]["attributes"]["levels"][0]["level_badges"][0]).to \
      eq("id" => 123, "level_id" => 456, "badge_id" => 789)
  end
end
