require 'rails_spec_helper'

# a cylon looks exactly the same, but is not the same.
# the whole point of the cylon is to include the S3File.
class S3FileCylon
  include S3File
end

RSpec.describe "An S3File inheritor" do
  subject { s3_file_cylon }

  let(:s3_file_cylon) { S3FileCylon.new }
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
    let(:tempfile) { Tempfile.new('walter') }
    subject { s3_file_cylon.s3_object_file_key }

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
