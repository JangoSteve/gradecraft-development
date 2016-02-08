require 'rails_spec_helper'

RSpec.describe SubmissionsExportPerformer, type: :background_job do
  include PerformerToolkit::SharedExamples
  include Toolkits::Performers::SubmissionsExport::SharedExamples
  extend Toolkits::Performers::SubmissionsExport::Context
  define_context

  subject { performer }

  describe "creating submission binary files" do
    let(:submissions) { [ submission_with_files, submission_without_files ] }
    let(:submission_with_files) { create(:submission, submission_files: submission_files, student: student) }
    let(:submission_without_files) { create(:submission, submission_files: []) }

    let(:submission_files) { [ submission_file1, submission_file2 ] }
    let(:submission_file1) { create(:submission_file, filename: "gary_ate_ants.ralph", file_missing: false) }
    let(:submission_file2) { create(:submission_file, file_missing: false) }

    let(:student) { create(:user, first_name: "Edwina", last_name: "Georgebot") }

    describe "create_submission_binary_files" do
      subject { performer.instance_eval { create_submission_binary_files } }
      before(:each) do
        performer.instance_variable_set(:@submissions, submissions)
      end

      describe "submission with files" do
        before { performer.instance_variable_set(:@submissions, [ submission_with_files ]) }
        it "creates a binary file for that submission" do
          expect(performer).to receive(:create_binary_files_for_submission).with(submission_with_files)
        end
      end

      describe "submission without files" do
        before { performer.instance_variable_set(:@submissions, [ submission_without_files ]) }
        it "doesn't create a binary file for that submission" do
          expect(performer).not_to receive(:create_binary_files_for_submission).with(submission_without_files)
        end
      end

      after(:each) { subject }
    end

    describe "create binary files for submission" do
      subject do
        performer.instance_eval { create_binary_files_for_submission( @some_submission ) }
      end

      describe "submission with files" do
        before do
          performer.instance_variable_set(:@some_submission, submission_with_files)
        end

        it "calls write_submission_binary_file for both submission files" do
          expect(performer).to receive(:write_submission_binary_file).twice
          subject
        end
      end

      describe "submission without files" do
        before { performer.instance_variable_set(:@some_submission, submission_without_files) }

        it "doesn't write any binary files" do
          expect(performer).not_to receive(:write_submission_binary_file)
          subject
        end
      end
    end

    describe "submission binary file name stuff" do
      before(:each) do
        performer.instance_variable_set(:@some_submission_file, submission_file1)
        performer.instance_variable_set(:@some_student, student)
      end

      let(:tmp_dir) { Dir.mktmpdir }

      describe "submission_binary_file_path" do
        subject do
          performer.instance_eval do
            submission_binary_file_path( @some_student, @some_submission_file, 5 )
          end
        end

        before do
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

      describe "submission_binary_filename" do
        subject do
          performer.instance_eval do
            submission_binary_filename( @some_student, @some_submission_file, 5 )
          end
        end

        before do
          allow(performer).to receive(:formatted_student_name) { "jeff_mills" }
          allow(performer).to receive(:formatted_assignment_name) { "the_wizard" }
        end

        it "gets the formatted student name from the student" do
          expect(performer).to receive(:formatted_student_name).with(student)
          subject
        end

        it "gets the formatted assignment name" do
          expect(performer).to receive(:formatted_assignment_name)
          subject
        end

        it "appends the index to 'submission_file'" do
          expect(subject).to include("Submission File 6")
        end

        it "gets the extension from the submission_file" do
          expect(submission_file1).to receive(:extension) { ".ralph" }
          subject
        end

        it "puts them all together and returns a filename" do
          expect(subject).to eq("jeff_mills - the_wizard - Submission File 6.ralph")
        end
      end

      describe "#write_submission_binary_file" do
        subject do
          performer.instance_eval do
            write_submission_binary_file( @some_student, @some_submission_file, 5 )
          end
        end

        let(:horses_path) { File.expand_path("horses.png", "spec/support/binary_files") }
        let(:mikos_bases_file_path) { "#{tmp_dir}/allyoarbases_r_belong_2_miko.snk" }

        before do
          allow(performer).to receive(:submission_binary_file_path) { mikos_bases_file_path }
          allow(submission_file1).to receive(:url) { horses_path }
        end

        it "gets the binary submission file path" do
          expect(performer).to receive(:submission_binary_file_path).with(student, submission_file1, 5)
          subject
        end

        it "streams the s3 file to the disk via the submission file" do
          expect(performer).to receive(:stream_s3_file_to_disk).with(submission_file1, mikos_bases_file_path)
          subject
        end
      end

      describe "#stream_s3_file_to_disk" do
        subject { performer.instance_eval { stream_s3_file_to_disk(@some_submission_file, @some_target_file_path) }}
        let(:s3_manager) { performer.instance_eval { s3_manager }}
        let(:mikos_bases_file_path) { "#{tmp_dir}/allyoarbases_r_belong_2_miko.snk" }

        let(:cache_ivars) do
          performer.instance_variable_set(:@some_submission_file, submission_file1)
          performer.instance_variable_set(:@some_target_file_path, mikos_bases_file_path)
        end

        before(:each) do
          allow(submission_file1).to receive(:s3_object_file_key) { "something-weird-happened-here" }
          cache_ivars
        end

        context "s3_manager#write_s3_manager_to_disk succeeds without error" do
          before do
            allow(s3_manager).to receive(:write_s3_object_to_disk) { true }
          end

          it "writes the s3 file to the file path for the archive directory" do
            expect(s3_manager).to receive(:write_s3_object_to_disk).with(submission_file1.s3_object_file_key, mikos_bases_file_path)
            subject
          end
        end

        context "s3_manager#write_s3_object_to_disk raises an Aws NoSuchKey error" do
          it "marks the submission file as missing" do
            expect(submission_file1).to receive(:mark_file_missing)
            subject
          end
        end
      end

      describe "remove_if_exists" do
        let(:horses_path) { File.expand_path("horses.png", "spec/support/binary_files") }
        let(:final_horses_path) { File.expand_path("horses.png", tmp_dir) }
        let(:clean_up_horses) { File.delete final_horses_path if File.exist? final_horses_path }
        let(:copy_horses) { FileUtils.cp horses_path, final_horses_path }

        subject do
          performer.instance_eval do
            remove_if_exists( @some_horses_path )
          end
        end

        before { performer.instance_variable_set(:@some_horses_path, final_horses_path) }

        context "nothing exists at file_path" do
          before { clean_up_horses }

          it "shouldn't bother deleting anything" do
            expect(File).not_to receive(:delete).with(final_horses_path)
            subject
          end
        end

        context "something exists at file_path" do
          before(:each) { copy_horses }

          it "calls File.delete on file_path if something's there" do
            expect(File).to receive(:delete).with(final_horses_path)
            subject
          end

          it "actually deletes the file at file_path" do
            subject
            expect(File.exist?(final_horses_path)).to be_falsey
          end
        end
      end

      describe "binary_file_error_message" do
        let(:message) { "the end of days is upon us" }
        let(:error_io) { "error dun blowed stuff up" }

        before(:each) do
          performer.instance_variable_set(:@some_message, message)
          performer.instance_variable_set(:@some_error_io, error_io)
        end

        subject do
          performer.instance_eval do
            binary_file_error_message( @some_message, @some_student, @some_submission_file, @some_error_io )
          end
        end

        it "includes the custom message from the particular type of error" do
          expect(subject).to include(message)
        end

        it "includes the student data" do
          expect(subject).to include("Student ##{student.id}: #{student.last_name}, #{student.first_name},")
        end

        it "includes the submission_file data" do
          expect(subject).to include("SubmissionFile ##{submission_file1.id}: #{submission_file1.filename},")
        end

        it "includes the io result from the rescued error block" do
          expect(subject).to include("error: #{error_io}")
        end
      end
    end
  end
end
