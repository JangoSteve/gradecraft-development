require 'rails_spec_helper'

include Toolkits::Uploaders::AttachmentUploader

RSpec.describe AttachmentUploader do
  let(:uploader) { AttachmentUploader.new(model, :file) }
  let(:model) { MockClass::FullUpFileKlass.new }

  describe "#course" do
    subject { uploader.instance_eval { course }}
    let(:course) { create(:course) }

    context "model has a course method" do

      before do
        allow(model).to receive(:course) { course }
      end

      it "returns a string with the format of <courseno-course_id>" do
        expect(subject).to eq("#{course.courseno}-#{course.id}")
      end
    end

    context "model has no course method" do
      let(:model) { MockClass::EmptyFileKlass.new }
      it "returns nil" do
        expect(subject).to be_nil
      end
    end
  end

  describe "#store_dir_pieces" do
    subject { uploader.instance_eval { store_dir_pieces }}
    before(:each) do
      allow(uploader).to receive_messages({
        course: "some-course",
        assignment: "some-assignment",
        file_klass: "devious_files",
        owner_name: "dave-eversby"
      })
    end

    it "returns an array with those components" do
      expect(subject).to eq([ "uploads", "some-course", "some-assignment", "devious_files", "dave-eversby" ])
    end

    it "compacts nils from the array" do
      allow(uploader).to receive_messages(course: nil, file_klass: nil)
      expect(subject).to eq([ "uploads", "some-assignment", "dave-eversby" ])
    end
  end

  describe "#assignment" do
    subject { uploader.instance_eval { assignment }}
    let(:assignment) { create(:assignment) }

    context "model has an assignment method" do
      before do
        allow(model).to receive(:assignment) { assignment }
      end

      it "returns a string with the format of <assignment_name-assignment_id>" do
        expect(subject).to eq("assignments/#{model.assignment.name.gsub(/\s/, "_").downcase[0..20]}-#{model.assignment.id}")
      end
    end

    context "model has no assignment method" do
      let(:model) { MockClass::EmptyFileKlass.new }
      it "returns nil" do
        expect(subject).to be_nil
      end
    end
  end

  describe "#file_klass" do
    subject { uploader.instance_eval { file_klass }}

    it "formats the name of the file class" do
      expect(subject.split("/").last).to eq "full_up_file_klasses"
    end
  end

  describe "#owner_name" do
    subject { uploader.instance_eval { owner_name }}

    context "model has an owner_name method" do
      before do
        allow(model).to receive(:owner_name) { " herman   jeffberry " }
      end

      it "returns a string with the format of <owner_name_name-owner_name_id>" do
        expect(subject).to eq "-herman---jeffberry-"
      end
    end

    context "model has no owner_name method" do
      let(:model) { MockClass::EmptyFileKlass.new }
      it "returns nil" do
        expect(subject).to be_nil
      end
    end
  end

  describe "#tokenized_name" do
    subject { uploader.instance_eval { tokenized_name }}
    let(:secure_token_name) { RandomFile::Content.random_string(20) }
    let(:secure_token_value) { RandomFile::Content.random_string(30) }
    let(:random_filename) { RandomFile::Content.random_string(40) }

    before(:each) do
      allow(uploader).to receive_messages({
        secure_token_name: :"@#{secure_token_name}",
        filename_from_basename: random_filename
      })
    end

    context "model has an instance variable with the secure_token_name" do
      before { model.instance_variable_set(:"@#{secure_token_name}", secure_token_value) }

      it "returns the value of the instance variable" do
        expect(subject).to eq(secure_token_value)
      end
    end

    context "model @secure_token_name is nil" do
      before { model.instance_variable_set(:"@#{secure_token_name}", nil) }

      it "sets the secure token name as the filename_from_basename" do
        subject
        expect(model.instance_variable_get(:"@#{secure_token_name}")).to eq random_filename
      end

      it "returns the filename_from_basename" do
        expect(subject).to eq random_filename
      end
    end
  end

  describe "#filename_from_basename" do
    subject { uploader.instance_eval { filename_from_basename }}
    let(:time_now) { Date.parse("Oct 20 1999").to_time }
    let(:file_basename) { "walter    was    acting%%$  #@ strange today%%%" }

    before do
      allow(Time).to receive(:now) { time_now }
      allow(uploader).to receive(:file) { double(:file, basename: file_basename) }
    end

    it "uses the time in microseconds and formats the basename" do
      expect(subject).to eq "#{time_now.to_i}_walter_was_acting_strange_today_"
    end
  end

  describe "#secure_token_name" do
    subject { uploader.instance_eval { secure_token_name }}
    let(:uploader) { AttachmentUploader.new(model, :berry_pancakes) }

    it "pulls the mounted_at value from the AttachmentUploader" do
      expect(subject).to eq :"@berry_pancakes_secure_token"
    end

    it "expects/uses a token named based on the #mounted_as value" do
      allow(uploader).to receive(:mounted_as) { "stuff_srsly" }
      expect(subject).to eq :"@stuff_srsly_secure_token"
    end
  end
end
