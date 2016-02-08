require 'rails_spec_helper'
require 'active_record_spec_helper'

RSpec.describe SubmissionsExport do
  let(:submissions_export) { SubmissionsExport.new }
  let(:s3_manager) { double(S3Manager::Manager) }
  let(:s3_object_key) { double(:s3_object_key) }

  describe "associations" do
    extend Toolkits::Exports::SubmissionsExportToolkit::Context
    define_association_context

    let(:submissions_export) { create(:submissions_export, submissions_export_associations) }
    subject { submissions_export }

    it "belongs to a course" do
      expect(subject.course).to eq(course)
    end

    it "belongs to a professor" do
      expect(subject.professor).to eq(professor)
    end

    it "belongs to a team" do
      expect(subject.team).to eq(team)
    end

    it "belongs to an assignment" do
      expect(subject.assignment).to eq(assignment)
    end
  end

  describe "#downloadable?" do
    subject { submissions_export.downloadable? }

    context "export has a last_export_completed_at time" do
      it "is downloadable" do
        submissions_export.last_export_completed_at = Time.now
        expect(subject).to be_truthy
      end
    end

    context "export doesn't have a last_export_completed_at time" do
      it "isn't download able" do
        submissions_export.last_export_completed_at = nil
        expect(subject).to be_falsey
      end
    end
  end

  describe "#created_at_date" do
    let(:submissions_export) { create(:submissions_export) }
    subject { submissions_export.created_at_date }

    it "formats the created_at date" do
      expect(subject).to eq(submissions_export.created_at.strftime("%F"))
    end
  end

  describe "#created_at_in_microseconds" do
    let(:submissions_export) { create(:submissions_export) }
    subject { submissions_export.created_at_in_microseconds }

    it "formats the created_at time in microseconds" do
      expect(subject).to eq(submissions_export.created_at.to_f.to_s.gsub(".",""))
    end
  end

  describe "validations" do
    describe "course_id" do
      subject { create(:submissions_export, course: nil) }
      it "requires a course_id" do
        expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    describe "assignment_id" do
      subject { create(:submissions_export, course: nil) }
      it "requires an assignment_id" do
        expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  describe "#build_s3_object_key" do
    let(:submissions_export) { create(:submissions_export) }
    let(:expected_base_s3_key) { "exports/courses/40/assignments/50/#{submissions_export.created_at_date}/#{submissions_export.created_at_in_microseconds}/stuff.zip" }
    subject { submissions_export.build_s3_object_key("stuff.zip") }

    before(:each) do
      allow(submissions_export).to receive_messages(course_id: 40, assignment_id: 50)
      ENV['AWS_S3_DEVELOPER_TAG'] = "jeff-moses"
    end

    context "env is development" do
      before do
        allow(Rails).to receive(:env) { ActiveSupport::StringInquirer.new("development") }
      end

      it "prepends the developer tag to the store dirs and joins them" do
        expect(subject).to eq ["jeff-moses", expected_base_s3_key].join("/")
      end
    end

    context "env is anything but development" do
      it "joins the store dirs and doesn't use the developer tag" do
        expect(subject).to eq expected_base_s3_key
      end
    end
  end

  describe "#s3_object_key_pieces" do
    subject { submissions_export.s3_object_key_pieces("stuff.zip") }
    let(:submissions_export) { create(:submissions_export) }
    let(:expected_object_key_pieces) do
      [
        "exports", "courses", 40, "assignments", 50,
        submissions_export.created_at_date,
        submissions_export.created_at_in_microseconds,
        "stuff.zip"
      ]
    end

    it "returns the expected pieces" do
      allow(submissions_export).to receive_messages(course_id: 40, assignment_id: 50)
      expect(subject).to eq(expected_object_key_pieces)
    end
  end

  describe "#s3_manager" do
    subject { submissions_export.s3_manager }

    it "creates an S3Manager::Manager object" do
      expect(subject.class).to eq(S3Manager::Manager)
    end

    it "caches the S3Manager object" do
      subject
      expect(S3Manager::Manager).not_to receive(:new)
      subject
    end
  end

  describe "#presigned_s3_url" do
    subject { submissions_export.presigned_s3_url }
    let(:submissions_export) { create(:submissions_export, s3_object_key: "some-test-key") }

    it "gets the presigned url for the s3 object" do
      expect(submissions_export.s3_manager).to receive_message_chain(:bucket, :object, :presigned_url, :to_s)
      subject
    end
  end

  describe "#upload_file_to_s3" do
    subject { submissions_export.upload_file_to_s3("great-file.txt") }

    before do
      allow(s3_manager).to receive(:put_encrypted_object) { "some s3 response" }
      allow(submissions_export).to receive(:s3_object_key) { "snake-hat-key" }
      allow(submissions_export).to receive(:s3_manager) { s3_manager }
    end

    it "puts an S3 encrypted object with the object key and file path" do
      expect(s3_manager).to receive(:put_encrypted_object).with("snake-hat-key", "great-file.txt")
      subject
    end

    it "returns the response from the S3 manager" do
      expect(subject).to eq("some s3 response")
    end
  end

  describe "#update_export_completed_time" do
    subject { submissions_export.update_export_completed_time }
    let(:sometime) { Time.parse("Oct 20 1982") }
    before { allow(submissions_export).to receive(:export_time) { sometime } }

    it "calls update_attributes on the submissions export with the export time" do
      expect(submissions_export).to receive(:update_attributes).with(last_export_completed_at: sometime)
      subject
    end

    it "updates the last_export_completed_at timestamp to now" do
      subject
      expect(submissions_export.last_export_completed_at).to eq(sometime)
    end
  end

  describe "#set_s3_bucket_name" do
    subject { submissions_export.set_s3_bucket_name }
    before do
      allow(submissions_export).to receive_message_chain(:s3_manager, :bucket_name) { "test-bucket" }
    end

    it "sets the submissions export value to the index in the s3_attributes hash" do
      subject
      expect(submissions_export[:s3_bucket_name]).to eq("test-bucket")
    end
  end

  describe "#s3_object_summary" do
    before do
      allow(submissions_export).to receive_messages(s3_object_key: s3_object_key, s3_manager: s3_manager)
    end

    subject { submissions_export.s3_object_summary }

    it "builds a new object summary with the object key and the s3 manager" do
      expect(S3Manager::Manager::ObjectSummary).to receive(:new).with(s3_object_key, s3_manager)
      subject
    end

    it "returns an ObjectSummary object" do
      expect(subject.class).to eq(S3Manager::Manager::ObjectSummary)
    end

    it "caches the new object summary" do
      subject
      expect(S3Manager::Manager::ObjectSummary).not_to receive(:new)
      subject
    end
  end

  describe "#export_time" do
    subject { submissions_export.instance_eval { export_time }}
    let(:parsed_time) { Date.parse("Oct 20 1452").to_time }
    before { allow(Time).to receive(:now) { parsed_time }}

    it "should return the time now" do
      expect(subject).to eq(parsed_time)
    end
  end

  describe "#s3_attributes" do
    subject { submissions_export.instance_eval { s3_attributes }}

    before do
      allow(submissions_export).to receive_message_chain(:s3_manager, :bucket_name) { "dave is home" }
      allow(submissions_export).to receive(:s3_object_key) { "some-key" }
    end

    it "should return a hash with the s3 object key and the s3 bucket name" do
      expect(subject).to eq({s3_bucket_name: "dave is home", s3_object_key: "some-key"})
    end
  end

end
