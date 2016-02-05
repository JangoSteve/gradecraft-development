require 'rails_spec_helper'

RSpec.describe AttachmentUploader do
  let(:uploader) { AttachmentUploader.new(model, :file) }
  let(:model) { double(SubmissionFile).as_null_object }

  describe "#course" do
    subject { uploader.instance_eval { course }}
    let(:course) { create(:course) }

    context "model has a course method" do
      class FileKlassWithCourse; def course; end; end
      let(:model) { FileKlassWithCourse.new }

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
        owner: "dave-eversby"
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
end
