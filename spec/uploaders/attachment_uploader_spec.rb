require 'rails_spec_helper'

RSpec.describe AttachmentUploader do
  let(:uploader) { AttachmentUploader.new(model, :file) }
  let(:model) { double(SubmissionFile).as_null_object }

  describe "#course" do
    context "model has a course method" do
      let(:course) { create(:course) }
      before { allow(model).to receive(:course) { course }}

      it "returns a string with the format of <courseno-course_id>" do
        expect(uploader.instance_eval { course }).to eq
      end
    end

    context "model has no course method" do
      it "returns nil" do
      end
    end
  end
end
