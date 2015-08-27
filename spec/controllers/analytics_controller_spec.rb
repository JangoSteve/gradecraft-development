#spec/controllers/analytics_controller_spec.rb
require 'spec_helper'

describe AnalyticsController do

	context "as a professor" do

    before do
      @course = create(:course_accepting_groups)
      @professor = create(:user)
      @professor.courses << @course
      @membership = CourseMembership.where(user: @professor, course: @course).first.update(role: "professor")
      @assignment_type = create(:assignment_type, course: @course)
      @assignment = create(:assignment, assignment_type: @assignment_type)
      @course.assignments << @assignment
      @student = create(:user)
      @student.courses << @course
      @students = []
      @students << @student

      login_user(@professor)
      session[:course_id] = @course.id
      allow(Resque).to receive(:enqueue).and_return(true)
    end

		describe "GET index" do
      it "returns analytics page for the current course" do
        get :index
        expect(assigns(:title)).to eq("User Analytics")
        expect(response).to render_template(:index)
      end
    end

		describe "GET students" do
      it "returns the student analytics page for the current course" do
        get :students
        expect(assigns(:title)).to eq("Player Analytics")
        expect(response).to render_template(:students)
      end
    end

		describe "GET staff" do
      it "returns the staff analytics page for the current course" do
        get :staff
        expect(assigns(:title)).to eq("team leader Analytics")
        expect(response).to render_template(:staff)
      end
    end

		describe "GET top_10" do
      it "returns the Top 10/Bottom 10 page for the current course" do
        get :top_10
        expect(assigns(:title)).to eq("Top 10/Bottom 10")
        expect(response).to render_template(:top_10)
      end
    end

		describe "GET per_assign" do
      it "returns the Assignment Analytics page for the current course" do
        get :per_assign
        expect(assigns(:title)).to eq("assignment Analytics")
        expect(response).to render_template(:per_assign)
      end
    end

    describe "GET all_events" do
      pending
    end

		describe "GET role_events" do
      pending
    end

		describe "GET assignment_events" do
      pending
    end

		describe "GET login_frequencies" do
      pending
    end

		describe "GET role_login_frequencies" do
      pending
    end

		describe "GET login_events" do
      pending
    end

		describe "GET login_role_events" do
      pending
    end

		describe "GET all_pageview_events" do
      pending
    end

		describe "GET all_role_pageview_events" do
      pending
    end

		describe "GET all_user_pageview_events" do
      pending
    end

		describe "GET pageview_events" do
      pending
    end

		describe "GET role_pageview_events" do
      pending
    end

		describe "GET user_pageview_events" do
      pending
    end

		describe "GET prediction_averages" do
      pending
    end

		describe "GET assignment_prediction_averages" do
      pending
    end

		describe "GET export" do
      pending
    end

	end

	context "as a student" do

	   describe "protected routes" do
          [
            :index,
            :students,
            :staff,
            :all_events,
            :top_10,
            :per_assign,
            :role_events,
            :assignment_events,
            :login_frequencies,
            :role_login_frequencies,
            :login_events,
            :login_role_events,
            :all_pageview_events,
            :all_role_pageview_events,
            :all_user_pageview_events,
            :pageview_events,
            :role_pageview_events,
            :user_pageview_events,
            :prediction_averages,
            :assignment_prediction_averages,
            :export

          ].each do |route|
              it "#{route} redirects to root" do
                expect(get route).to redirect_to(:root)
              end
            end
        end

	end

end
