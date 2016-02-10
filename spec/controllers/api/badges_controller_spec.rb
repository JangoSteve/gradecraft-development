require 'rails_spec_helper'

describe API::BadgesController do
  let(:world) { World.create.with(:course, :student, :badge) }
  let(:professor) { create(:professor_course_membership, course: world.course).user }

  context "as professor" do
    before(:each) { login_user(professor) }

    describe "GET index" do
      it "returns badges for the current course" do
        get :index, format: :json
        expect(assigns(:badges)).to eq([world.badge])
        expect(response).to render_template(:index)
      end
    end
  end
end
