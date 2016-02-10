require 'rails_spec_helper'

describe API::GradesController do
  let(:world) { World.create.with(:course, :student, :assignment, :grade) }
  let(:professor) { create(:professor_course_membership, course: world.course).user }

  context "as professor" do
    before(:each) { login_user(professor) }

    describe "GET show" do
      it "returns a student's grade for the current assignment" do
        get :show, id: world.assignment.id, student_id: world.student.id, format: :json
        expect(assigns(:grade).id).to eq(world.grade.id)
        expect(response).to render_template(:show)
      end
    end
  end

  context "as student" do
    before(:each) { login_user(world.student) }

    describe "GET show" do
      it "is a protected route" do
        expect(get :show, id: world.assignment.id, student_id: world.student.id, format: :json).to redirect_to(:root)
      end
    end
  end
end
