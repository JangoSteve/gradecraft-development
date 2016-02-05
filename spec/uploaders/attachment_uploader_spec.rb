require 'rails_spec_helper'

include Toolkits::Uploaders::AttachmentUploader

RSpec.describe AttachmentUploader do
  let(:uploader) { AttachmentUploader.new(model, :file) }
  let(:model) { double(SubmissionFile).as_null_object }

  describe "#course" do
    subject { uploader.instance_eval { course }}
    let(:course) { create(:course) }

    context "model has a course method" do
      let(:model) { MockClass::FullUpFileKlass.new }

      before do
        allow(model).to receive(:course) { course }
      end

      it "returns a string with the format of <courseno-course_id>" do
        expect(subject).to eq("#{course.courseno}-#{course.id}")
      end
    end

    context "model has no course method" do
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
      let(:model) { MockClass::FullUpFileKlass.new }

      before do
        allow(model).to receive(:assignment) { assignment }
      end

      it "returns a string with the format of <assignment_name-assignment_id>" do
        expect(subject).to eq("assignments/#{model.assignment.name.gsub(/\s/, "_").downcase[0..20]}-#{model.assignment.id}")
      end
    end

    context "model has no assignment method" do
      it "returns nil" do
        expect(subject).to be_nil
      end
    end
  end

  describe "#file_klass" do
    subject { uploader.instance_eval { file_klass }}
    let(:model) { MockClass::FullUpFileKlass.new }

    it "formats the name of the file class" do
      expect(subject.split("/").last).to eq "full_up_file_klasses"
    end
  end

  describe "#owner_name" do
    subject { uploader.instance_eval { owner_name }}

    context "model has an owner_name method" do
      let(:model) { MockClass::FullUpFileKlass.new }

      before do
        allow(model).to receive(:owner_name) { " herman   jeffberry " }
      end

      it "returns a string with the format of <owner_name_name-owner_name_id>" do
        expect(subject).to eq "-herman---jeffberry-"
      end
    end

    context "model has no owner_name method" do
      it "returns nil" do
        expect(subject).to be_nil
      end
    end
  end
end
