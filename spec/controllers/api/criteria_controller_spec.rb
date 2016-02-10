require 'rails_spec_helper'

describe API::CriteriaController do
  let(:world) { World.create.with(:course, :student, :assignment, :rubric, :criterion, :criterion_grade) }
  let(:professor) { create(:professor_course_membership, course: world.course).user }

  context "as professor" do
    before(:each) { login_user(professor) }

    describe "GET criteria" do
      it "returns criteria for the current assignment" do
        get :index, id: world.assignment.id, format: :json
        expect(assigns(:criteria)[0].id).to eq(world.criteria[0].id)
        expect(response).to render_template(:index)
      end
    end
  end
end
