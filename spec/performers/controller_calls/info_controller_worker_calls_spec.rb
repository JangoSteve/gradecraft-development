require 'rails_spec_helper'

include ResqueJobSharedExamplesToolkit

RSpec.describe InfoController, type: :controller, background_job: true do
  include InQueueHelper

  let(:course) { create(:course_accepting_groups) }
  let(:professor) { create(:user) }
  let(:enroll_professor) { CourseMembership.create(job_attributes.merge(role: "professor")) }
  let(:job_attributes) {{user_id: professor.id, course_id: course.id }}

  before do
    enroll_professor
    login_user(professor)
    session[:course_id] = course.id
  end

  before(:each) { ResqueSpec.reset! }

  describe "#gradebook" do
    subject { get :gradebook }

    it_behaves_like "a successful resque job", GradebookExporterJob
  end

  describe "#research_gradebook" do
    subject { get :research_gradebook }

    it_behaves_like "a successful resque job", GradeExportJob
  end
end
