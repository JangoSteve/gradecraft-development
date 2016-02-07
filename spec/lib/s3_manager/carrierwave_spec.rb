require 'rails_spec_helper'

RSpec.describe S3Manager::Carrierwave do
  subject { s3_file_cylon }

  let(:s3_file_cylon) { SubmissionFile.new }
  let(:s3_manager) { S3Manager::Manager.new }
  let(:source_object) { Tempfile.new('walter-srsly') }
  let(:s3_object_key) { "lets-see-what-happens.txt" }
  let(:object_exists?) { s3_file_cylon.exists_on_s3? }
  let(:put_object_to_s3) { s3_manager.put_object(s3_object_key, source_object) }

  describe "inclusion of S3Manager::Basics" do
    it "responds to S3Manager::Basics methods" do
      expect(subject).to respond_to(:object_attrs)
      expect(subject).to respond_to(:bucket_name)
    end
  end

  describe "#url" do
    subject(:each) { s3_file_cylon.url }

    let(:presigned_url) { double(:presigned_url).as_null_object }
    let(:s3_object) { double(:s3_object).as_null_object }

    before(:each) do
      allow(s3_file_cylon).to receive_message_chain(:file, :url) { "great url, bro" }
      allow(s3_file_cylon).to receive(:filepath) { "sumpin'" }
      allow(s3_file_cylon).to receive(:s3_object) { s3_object }
      allow(s3_object).to receive(:presigned_url) { presigned_url }
    end

    it "gets the presigned url for the s3 object" do
      expect(s3_object).to receive(:presigned_url).with(:get, expires_in: 900)
    end

    it "converts all of that into a string" do
      expect(presigned_url).to receive(:to_s)
    end

    after(:each) { subject }
  end

  describe "#s3_object" do
    subject(:each) { s3_file_cylon.s3_object }

    let(:bucket) { double(:bucket).as_null_object }
    let(:object) { double(:object).as_null_object }
    let(:s3_object_file_key) { "hopefully-this-never-happens" }

    before(:each) do
      allow(s3_file_cylon).to receive(:bucket) { bucket }
      allow(bucket).to receive(:object) { object }
      allow(s3_file_cylon).to receive_messages({
        bucket: bucket,
        s3_object_file_key: s3_object_file_key
      })
    end

    it "fetches the bucket object with the s3_object_file_key" do
      expect(bucket).to receive(:object).with(s3_object_file_key)
    end

    after(:each) { subject }
  end

  describe "#s3_object_file_key" do
    subject { s3_file_cylon.s3_object_file_key }
    let(:tempfile) { Tempfile.new('walter') }

    context "cached_file_path is present" do
      before { allow(s3_file_cylon).to receive(:cached_file_path) { "/some/great/path.png" }}

      it "returns the cached file path" do
        expect(subject).to eq "/some/great/path.png"
      end
    end

    context "filepath is present" do
      before { allow(s3_file_cylon).to receive(:filepath) { tempfile }}

      it "returns the CGI-unescaped filepath" do
        expect(CGI).to receive(:unescape).with(tempfile)
        subject
      end
    end

    context "filepath is not present" do
      before do
        allow(s3_file_cylon).to receive(:filepath) { nil }
        allow(s3_file_cylon).to receive_message_chain(:file, :path) { "/stuff/path" }
      end

      it "returns the #path from the file" do
        expect(subject).to eq("/stuff/path")
      end
    end
  end

  describe "#cached_file_path" do
    subject { s3_file_cylon.cached_file_path }
    before do
      allow(s3_file_cylon).to receive_messages(store_dir: "great_dir", filename: "stuff.txt")
    end

    context "both store_dir and filename exist" do
      it "joins the store_dir and the filename with a forward slash" do
        expect(subject).to eq "great_dir/stuff.txt"
      end

      it "caches the joined cached_file_path value" do
        first_call = subject
        expect(first_call.object_id).to eq(subject.object_id)
      end
    end

    context "either store_dir or filename does not exist" do
      before { allow(s3_file_cylon).to receive(:store_dir) { nil }}
      it "returns nil" do
        expect(subject).to be_nil
      end
    end
  end

  describe "#cache_store_dir" do
    subject { s3_file_cylon.instance_eval { cache_store_dir }}
    before { allow(s3_file_cylon).to receive(:file) { double(:file, store_dir: "some-dir") }}

    it "caches the store_dir attribute" do
      subject
      expect(s3_file_cylon[:store_dir]).to eq("some-dir")
    end
  end

  describe "caching the store_dir before create" do
    let(:create_submission_file) { create(:submission_file) }
    before do
      allow_any_instance_of(AttachmentUploader).to receive(:store_dir) { "some-dir" }
      create_submission_file
    end

    it "caches the store_dir before create" do
      expect(create_submission_file[:store_dir]).to eq("some-dir")
    end
  end

  describe "#delete_from_s3" do
    subject { s3_file_cylon.delete_from_s3 }

    let(:bucket) { double(:bucket).as_null_object }
    let(:object) { double(:object).as_null_object }
    let(:s3_object_file_key) { "hopefully-this-never-happens" }

    before(:each) do
      allow(s3_file_cylon).to receive_messages({
        bucket: bucket,
        s3_object_file_key: s3_object_file_key
      })
      allow(bucket).to receive(:object) { object }
    end

    it "fetches the bucket object with the s3_object_file_key" do
      expect(bucket).to receive(:object).with(s3_object_file_key)
    end

    it "gets the presigned url for the object" do
      expect(object).to receive(:delete)
    end

    after(:each) { subject }
  end

  describe "actually deleting the object" do
    subject { s3_file_cylon.delete_from_s3 }

    before(:each) do
      allow(s3_file_cylon).to receive(:s3_object_file_key) { s3_object_key }
    end

    context "file exists on server" do
      before(:each) { put_object_to_s3 }

      it "should actually be operating on a file that's present to begin with" do
        expect(object_exists?).to be_truthy
      end

      it "actually removes the object from the server" do
        subject
        expect(object_exists?).to be_falsey
      end

      it "returns an Aws::S3::Types::DeleteObjectOutput object" do
        expect(subject.class).to eq(Seahorse::Client::Response)
      end
    end
  end

  describe "#exists_on_s3?" do
    subject { s3_file_cylon.exists_on_s3? }

    before(:each) do
      allow(s3_file_cylon).to receive(:s3_object_file_key) { s3_object_key }
    end

    context "file exists on server" do
      it "returns a truthy value" do
        put_object_to_s3
        expect(subject).to be_truthy
        s3_file_cylon.delete_from_s3 # clean up the file
      end
    end

    context "file does not exist on server" do
      it "returns an Aws::S3::Types::DeleteObjectOutput object" do
        expect(subject).to be_falsey
      end
    end
  end
end
