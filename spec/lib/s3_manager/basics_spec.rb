require 'rails_spec_helper'

include Toolkits::S3Manager::BasicsToolkit

RSpec.describe S3Manager::Manager do
  let(:s3_manager) { S3Manager::Manager.new }

  describe "#client" do
    subject { s3_manager.client }

    it "builds a new S3 client" do
      expect(subject.class).to eq(Aws::S3::Client)
    end

    it "uses the correct env variables for the client" do
      expect(Aws::S3::Client).to receive(:new).with(client_attributes)
      subject
    end

    it "caches the client" do
      subject
      expect(Aws::S3::Client).not_to receive(:new)
      subject
    end
  end

  describe "#resource" do
    subject { s3_manager.resource }

    it "builds a new S3 Resource object" do
      expect(subject.class).to eq(Aws::S3::Resource)
    end

    it "caches the resource" do
      subject
      expect(Aws::S3::Resource).not_to receive(:new)
      subject
    end
  end

  describe "#bucket" do
    subject { s3_manager.bucket }

    it "builds a new s3 client" do
      expect(s3_manager).to receive(:client)
      subject
    end

    it "gets the s3 bucket from the resource" do
      expect(subject.class).to eq(Aws::S3::Bucket)
    end

    it "caches the bucket" do
      subject
      expect(s3_manager).not_to receive(:resource)
      subject
    end
  end

  describe "#bucket_name" do
    before do
      ENV['AWS_S3_BUCKET'] = "some-bucket-name"
    end

    it "should use the bucketname from AWS_S3_BUCKET" do
      expect(s3_manager.bucket_name).to eq("some-bucket-name")
    end

    after do
      ENV['AWS_S3_BUCKET'] = "gradecraft-test"
    end
  end

  describe"#object_attrs" do
    it "returns a hash of attributes for a new object" do
      allow(s3_manager).to receive(:bucket_name) { "walrus-bucket" }
      expect(s3_manager.object_attrs).to eq({ bucket: "walrus-bucket" })
    end
  end

  describe "object management" do
    let(:s3_manager) { S3Manager::Manager.new }
    let(:object_key) { "jerrys-unencrypted-hat" }
    let(:client) { s3_manager.client }
    let(:filename) { "unencrypted-jerry-was-here.doc" }
    let(:object_body) { File.new(filename, "w+b") }
    let(:put_object) { s3_manager.put_object(object_key, object_body) }
    let(:delete_jerry) { FileUtils.rm(filename) if File.exist?(filename) }

    before(:each) { client }

    describe "#delete_object" do
      subject { s3_manager.delete_object(object_key) }

      before(:each) { put_object }

      let(:delete_object_attrs) do
        { bucket: s3_manager.bucket_name, key: object_key }
      end

      it "should call #delete_object on the client" do
        expect(client).to receive(:delete_object).with(delete_object_attrs)
        subject
      end

      it "should get an AWS Seahorse object in response" do
        expect(subject.class).to eq(Seahorse::Client::Response)
      end

      it "should have been successful" do
        expect(subject.successful?).to be_truthy
      end

      it "should actually remove the object from the server" do
        subject
        expect(S3Manager::Manager::ObjectSummary.new(object_key, s3_manager).exists?).to be_falsey
      end

      after(:each) { delete_jerry }
    end

    describe "#get_object" do
      subject { s3_manager.get_object(object_key) }

      before { put_object }

      let(:get_object_attrs) do
        { bucket: s3_manager.bucket_name, key: object_key }
      end

      it "should call #get_object on the client" do
        expect(client).to receive(:get_object)
        subject
      end

      it "should get an AWS Seahorse object in response" do
        expect(subject.class).to eq(Seahorse::Client::Response)
      end

      it "should have been successful" do
        expect(subject.successful?).to be_truthy
      end

      it "should have the correct body of the gotten object" do
        expect(client).to receive(:get_object).with(get_object_attrs)
        subject
      end

      it "should suggest that AES256 encryption was used" do
        expect(subject.server_side_encryption).to eq("AES256")
      end

      after { FileUtils.rm(filename) if File.exist?(filename) }
    end

    describe "#write_s3_object_to_disk" do
      subject { s3_manager.write_s3_object_to_disk(object_key, target_file_path) }
      let(:target_file_path) { Tempfile.new('something-new') }
      let(:target_file_size) { File.stat(target_file_path).size }

      context "file actually exists on s3" do
        let(:original_file_path) { Tempfile.new('something-old').path }
        let(:original_file) { RandomFile::TextFile.new(original_file_path) }
        let(:original_file_size) { original_file.size }
        let(:read_original_file) { File.open(original_file_path, "rb") }
        let(:put_object) { s3_manager.put_object(object_key, read_original_file) }

        before(:each) { original_file.write; put_object }

        let(:get_object_attrs) do
          { response_target: target_file_path, bucket: s3_manager.bucket_name, key: object_key }
        end

        it "should call #get_object on the client" do
          expect(client).to receive(:get_object)
          subject
        end

        it "should get an AWS Seahorse object in response" do
          expect(subject.class).to eq(Seahorse::Client::Response)
        end

        it "should have been successful" do
          expect(subject.successful?).to be_truthy
        end

        it "should have the correct body of the gotten object" do
          expect(client).to receive(:get_object).with(get_object_attrs)
          subject
        end

        it "should suggest that AES256 encryption was used" do
          expect(subject.server_side_encryption).to eq("AES256")
        end

        it "should have written a file to the target path" do
          subject
          expect(File.exist?(target_file_path)).to be_truthy
        end

        it "should have written a file of the same size as the target file" do
          subject
          expect(target_file_size).to eq(original_file_size)
        end

        after(:each) do
          FileUtils.rm(original_file_path) if File.exist?(original_file_path)
          FileUtils.rm(target_file_path) if File.exist?(target_file_path)
        end
      end

      context "object key is invalid or object doesn't exist" do
        let(:object_key) { RandomFile::Content.random_string(100) }
        it "should raise an error" do
          expect { subject }.to raise_error(Aws::S3::Errors::NoSuchKey)
        end
      end
    end

    describe "#put_object" do
      let(:file_path) { Tempfile.new('something-old').path }
      let(:put_object) { s3_manager.put_object(object_key, file_path) }
      subject { put_object }

      it "should call #put_object on the encrypted client" do
        expect(s3_manager).to receive(:put_object_with_client).with(client, object_key, file_path)
        subject
      end
    end
  end
end
