require "rails_spec_helper"

describe SubmissionFile do
  let(:course) { build(:course) }
  let(:assignment) { build(:assignment) }
  let(:student) { build(:user) }
  let(:submission) { build(:submission, course: course, assignment: assignment, student: student) }
  let(:submission_file) { submission.submission_files.last }

  describe "#source_file_url" do
    subject { submission_file.source_file_url }

    it "uses the url method from S3File" do
      allow(submission_file).to receive(:url) { "http://werewolf.com" }
      expect(subject).to eq("http://werewolf.com")
    end
  end

  describe "#s3_manager" do
    subject { submission_file.s3_manager }
    let(:submission_file) { build(:submission_file) }

    it "creates an S3Manager::Manager object" do
      expect(subject.class).to eq(S3Manager::Manager)
    end

    it "caches the S3Manager object" do
      subject
      expect(S3Manager::Manager).not_to receive(:new)
      subject
    end
  end

  describe "#check_and_set_confirmed_status" do
    subject { submission_file.check_and_set_confirmed_status }
    let(:submission_file) { build(:submission_file) }
    let(:someday) { Date.parse("June 20 2502").to_time }

    before do
      allow(Time).to receive(:now) { someday }
      allow(submission_file).to receive(:file_missing?) { "probably" }
    end

    it "checks whether the file is missing and updates the confirmed attributes" do
      expect(submission_file).to receive(:update_attributes).with(file_missing: "probably", last_confirmed_at: someday)
      subject
    end
  end

  describe "#mark_file_missing" do
    subject { submission_file.mark_file_missing }
    let(:submission_file) { create(:submission_file, file_missing: false, last_confirmed_at: Time.now) }
    let(:someday) { Date.parse("June 20 2502").to_time }

    before do
      allow(Time).to receive(:now) { someday }
    end

    it "sets the file as missing and updates the last confirmed day" do
      expect(submission_file).to receive(:update_attributes).with(file_missing: true, last_confirmed_at: someday)
      subject
    end

    it "actually updates the submission file" do
      subject
      expect(submission_file[:file_missing]).to be_truthy
      expect(submission_file[:last_confirmed_at]).to eq(someday)
    end
  end

  describe "#file_missing?" do
    subject { submission_file.file_missing? }
    let(:submission_file) { build(:submission_file) }
    before { allow(submission_file).to receive(:exists_on_storage?) { false }}

    it "negates #exists_on_storage?" do
      expect(subject).to be_truthy
    end
  end

  describe "#exists_on_storage?" do
    subject { submission_file.exists_on_storage? }
    let(:submission_file) { build(:submission_file) }
    let(:public_url) { Tempfile.new('waffle') }

    context "Rails env is development" do
      before do
        allow(Rails).to receive(:env) { ActiveSupport::StringInquirer.new("development") }
        allow(submission_file).to receive(:public_url) { public_url }
      end

      it "checks if a file exists at the public url" do
        expect(File).to receive(:exist?).with(public_url)
        subject
      end
    end

    context "Rails env is anything but development" do
      let(:s3_manager) { double(S3Manager) }
      let(:s3_object_summary) { double(S3Manager::Manager::ObjectSummary).as_null_object }
      let(:s3_object_file_key) { "really-this-shouldnt-make-it.txt" }

      before do
        allow(Rails).to receive(:env) { ActiveSupport::StringInquirer.new("test") }
        allow(submission_file).to receive_messages({
          s3_object_file_key: s3_object_file_key,
          s3_manager: s3_manager
        })
        allow(S3Manager::Manager::ObjectSummary).to receive(:new) { s3_object_summary }
      end

      it "builds a new S3 object summary with the object file key and s3 manager" do
        expect(S3Manager::Manager::ObjectSummary).to receive(:new).with(s3_object_file_key, s3_manager)
        subject
      end

      it "checks whether the object exists" do
        expect(s3_object_summary).to receive(:exists?)
        subject
      end
    end
  end

end
