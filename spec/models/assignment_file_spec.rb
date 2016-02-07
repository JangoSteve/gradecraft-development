require "active_record_spec_helper"

describe AssignmentFile do
  let(:assignment) { build(:assignment) }

  subject { assignment.assignment_files.new(filename: "test", file: fixture_file('test_image.jpg', 'img/jpg')) }

  describe "validations" do
    it "requires a filename" do
      subject.filename = nil
      expect(subject).to_not be_valid
      expect(subject.errors[:filename]).to include "can't be blank"
    end
  end

  describe "as a dependency of the submission" do
    it "is saved when the parent submission is saved" do
      subject.assignment.save!
      expect(subject.assignment_id).to equal assignment.id
      expect(subject.new_record?).to be_falsey
    end

    it "is deleted when the parent submission is destroyed" do
      subject.assignment.save!
      expect { assignment.destroy }.to change(AssignmentFile, :count).by(-1)
    end
  end

  it "accepts text files as well as images" do
    subject.file = fixture_file('test_file.txt', 'txt')
    subject.assignment.save!
    expect expect(subject.url).to match(/.*\/uploads\/assignment_file\/file\/#{subject.id}\/\d+_test_file\.txt/)
  end

  it "accepts multiple files" do
    assignment.assignment_files.new(filename: "test", file: fixture_file('test_file.txt', 'img/jpg'))
    subject.assignment.save!
    expect(assignment.assignment_files.count).to equal 2
  end

  it "has an accessible url" do
    subject.assignment.save!
    expect expect(subject.url).to \
      match(/.*\/uploads\/assignment_file\/file\/#{subject.id}\/\d+_test_image\.jpg/)
  end

  it "shortens and removes non-word characters from file names on save" do
    subject.file = fixture_file('Too long, strange characters, and Spaces (In) Name.jpg', 'img/jpg')
    subject.assignment.save!
    expect expect(subject.url).to \
      match(/.*\/uploads\/assignment_file\/file\/#{subject.id}\/\d+_too_long__strange_characters__and_spaces_\.jpg/)
  end

  describe "#course" do
    it 'returns the associated course' do
      course = create(:course)
      assignment.course = course
      expect(subject.course).to eq(course)
    end
  end

  describe "S3Manager::Carrierwave inclusion" do
    let(:assignment_file) { build(:assignment_file) }

    it "can be deleted from s3" do
      expect(assignment_file.respond_to?(:delete_from_s3)).to be_truthy
    end

    it "can check whether it exists on s3" do
      expect(assignment_file.respond_to?(:exists_on_s3?)).to be_truthy
    end
  end
end
