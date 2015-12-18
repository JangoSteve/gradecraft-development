# encoding: utf-8
require 'rails_spec_helper'

describe "pages/features" do

  it "renders successfully" do
    render
    assert_select "h1", text: "Features to Bring Gameful Experiences to the Classroom", :count => 1
  end

end
