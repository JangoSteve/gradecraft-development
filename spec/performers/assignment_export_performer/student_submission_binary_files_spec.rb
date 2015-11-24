require 'rails_spec_helper'

RSpec.describe AssignmentExportPerformer, type: :background_job do
  include PerformerToolkit::SharedExamples
  include Toolkits::Performers::AssignmentExport::SharedExamples
  include ModelAddons::SharedExamples

  extend Toolkits::Performers::AssignmentExport::Context
  define_context

  subject { performer }

  describe "creating submission binary files" do
    let(:submissions) { [ submission_with_files, submission_without_files ] }
    let(:submission_with_files) { double(:submission, submission_files: submission_files, student: student) }
    let(:submission_without_files) { double(:submission, submission_files: []) }

    let(:submission_files) { [ submission_file1, submission_file2 ] }
    let(:submission_file1) { double(:submission_file) }
    let(:submission_file2) { double(:submission_file) }

    let(:student) { double(:student) }

    describe "create_submission_binary_files" do
      subject { performer.instance_eval { create_submission_binary_files } }
      before { performer.instance_variable_set(:@submissions, submissions) }

      describe "submission with files" do
        it "creates a binary file for that submission" do
          expect(performer).to receive(:create_binary_files_for_submission).with(submission_with_files)
        end
      end

      describe "submission without files" do
        it "doesn't create a binary file for that submission" do
          expect(performer).not_to receive(:create_binary_files_for_submission).with(submission_without_files)
        end
      end

      after(:each) { subject }
    end

    describe "create binary files for submission" do
      subject { performer.instance_eval { create_binary_files_for_submission( @some_submission ) } }

      describe "submission with files" do
        before do
          performer.instance_variable_set(:@some_submission, submission_with_files)
          allow(performer).to receive(:write_submission_binary_file)
        end

        it "calls write_submission_binary_file for submission_file1" do
          expect(performer).to receive(:write_submission_binary_file).with(student, submission_file1, 0)
        end

        it "calls write_submission_binary_file for submission_file2" do
          expect(performer).to receive(:write_submission_binary_file).with(student, submission_file2, 1)
        end

        after(:each) { subject }
      end

      describe "submission without files" do
        before { performer.instance_variable_set(:@some_submission, submission_without_files) }

        it "doesn't write any binary files" do
          expect(performer).not_to receive(:write_submission_binary_file)
          subject
        end
      end
    end

    describe "submission_binary_file_path" do
      subject { performer.instance_eval { submission_binary_file_path( @some_student, @some_submission_file, 5 ) } }

      before do
        performer.instance_variable_set(:@some_submission_file, submission_file1)
        performer.instance_variable_set(:@some_student, student)

        allow(performer).to receive(:submission_binary_filename) { "sweet_keith.potr" } # sweet keith pooped on the rug
        allow(performer).to receive(:student_directory_file_path)
      end

      it "builds a binary filename based on the arguments" do
        expect(performer).to receive(:submission_binary_filename).with( student, submission_file1, 5 )
      end

      it "returns a full path for the file relative to the student directory" do
        expect(performer).to receive(:student_directory_file_path).with( student, "sweet_keith.potr" )
      end

      after(:each) { subject }
    end

  end
end
