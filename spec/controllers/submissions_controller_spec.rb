require "rails_spec_helper"

describe SubmissionsController do
  before(:all) do
    @course = create(:course)
    @student = create(:user)
    @student.courses << @course
    @assignment = create(:assignment, course: @course)
  end
  before(:each) do
    session[:course_id] = @course.id
    allow(Resque).to receive(:enqueue).and_return(true)
  end

  context "as a professor" do
    before(:all) do
      @professor = create(:user)
      CourseMembership.create user: @professor, course: @course, role: "professor"
    end
    before(:each) do
      @submission = create(:submission, assignment_id: @assignment.id, assignment_type: "Assignment", student_id: @student.id, course_id: @course.id)
      login_user(@professor)
    end

    describe "GET show" do
      it "returns the submission show page" do
        get :show, {:id => @submission.id, :assignment_id => @assignment.id}
        expect(response).to render_template(:show)
      end
    end

    describe "GET new" do
      it "returns the submission new page" do
        get :new, {:id => @submission.id, :assignment_id => @assignment.id}
        expect(response).to render_template(:new)
      end
    end

    describe "GET edit" do
      it "display the edit form" do
        get :edit, {:id => @submission.id, :assignment_id => @assignment.id}
        expect(response).to render_template(:edit)
      end
    end

    describe "POST create" do
      it "creates the submission with valid attributes"  do
        params = attributes_for(:submission)
        expect{ post :create, :assignment_id => @assignment.id, :submission => params }.to change(Submission,:count).by(1)
      end

      it "manages submission file uploads" do
        params = attributes_for(:submission).merge(student_id: @student.id)
        params.merge! submission_files_attributes: {"0" => {file: [fixture_file('test_file.txt', 'txt')]}}
        post :create, assignment_id: @assignment.id, submission: params
        submission = Submission.unscoped.last
        expect(submission.submission_files.count).to eq 1
        expect(submission.submission_files[0].filename).to eq "test_file.txt"
      end

      it "does not create the submission for large files" do
        params = attributes_for(:submission)
        file = fixture_file('test_file.txt', 'txt')
        allow_any_instance_of(AttachmentUploader).to receive(:size).and_return 50_000_000
        params.merge! submission_files_attributes: {"0" => {file: [file]}}
        post :create, assignment_id: @assignment.id, submission: params
        expect(response).to render_template :new
      end
    end

    describe "POST update" do
      it "updates the submission successfully"  do
        params = attributes_for(:submission)
        params[:assignment_id] = @assignment.id
        params[:text_comment] = "Ausgezeichnet"
        post :update, :assignment_id => @assignment.id, :id => @submission, :submission => params
        expect(response).to redirect_to(assignment_submission_path(@assignment, @submission, student_id: @student.id))
        expect(@submission.reload.text_comment).to eq("Ausgezeichnet")
      end
    end

    describe "GET destroy" do
      it "destroys the submission" do
        expect{ get :destroy, {:id => @submission, :assignment_id => @assignment.id } }.to change(Submission,:count).by(-1)
      end
    end
  end

  context "as a student" do
    before do
      @submission = create(:submission, assignment_id: @assignment.id,
                           assignment_type: "Assignment", student_id: @student.id,
                           course_id: @course.id)
      login_user(@student)
    end

    describe "GET edit" do
      it "shows the edit submission form" do
        get :edit, {:id => @submission.id, :assignment_id => @assignment.id}
        expect(response).to render_template(:edit)
      end
    end

    describe "POST create" do
      it "creates the submission with valid attributes" do
        params = attributes_for(:submission, student_id: @student.id)
          .merge(assignment_id: @assignment_id)
        expect { post :create, assignment_id: @assignment.id, submission: params }.to \
          change(Submission,:count).by(1)
      end

      it "timestamps the submission" do
        params = attributes_for(:submission, student_id: @student.id)
          .merge(assignment_id: @assignment_id)
        current_time = DateTime.now
        post :create, assignment_id: @assignment.id, submission: params
        submission = Submission.unscoped.last
        expect(submission.submitted_at).to be > current_time
      end
    end

    describe "PUT update" do
      it "updates the submission successfully"  do
        params = attributes_for(:submission).merge({ assignment_id: @assignment.id })
        params[:text_comment] = "Ausgezeichnet"
        put :update, assignment_id: @assignment.id, id: @submission, submission: params
        expect(response).to redirect_to(assignment_path(@assignment, :anchor => "tab3"))
        expect(@submission.reload.text_comment).to eq("Ausgezeichnet")
      end

      it "timestamps the submission" do
        params = attributes_for(:submission).merge({ assignment_id: @assignment.id })
        params[:text_comment] = "Ausgezeichnet"
        current_time = DateTime.now
        put :update, assignment_id: @assignment.id, id: @submission, submission: params
        expect(@submission.reload.submitted_at).to be > current_time
      end
    end

    describe "protected routes requiring id in params" do
      [
        :show,
        :destroy
      ].each do |route|
        it "#{route} redirects to root" do
          expect(get route, {:assignment_id => 1, :id => "1"}).to redirect_to(:root)
        end
      end
    end
  end
end
