require "active_record_spec_helper"

describe GradeFile do
  let(:course) { build(:course) }
  let(:assignment) { build(:assignment, course: course) }
  let(:grade) { build(:grade, course: course, assignment: assignment) }

  subject { grade.grade_files.new(filename: "test", file: fixture_file('test_image.jpg', 'img/jpg')) }

  describe "validations" do
    it { is_expected.to be_valid }

    it "requires a filename" do
      subject.filename = nil
      expect(subject).to_not be_valid
      expect(subject.errors[:filename]).to include "can't be blank"
    end
  end

  describe "as a dependency of the submission" do
    it "is saved when the parent submission is saved" do
      subject.grade.save!
      expect(subject.grade_id).to equal grade.id
      expect(subject.new_record?).to be_falsey
    end

    it "is deleted when the parent submission is destroyed" do
      subject.grade.save!
      expect {grade.destroy}.to change(GradeFile, :count).by(-1)
    end
  end

  it "accepts text files as well as images" do
    subject.file = fixture_file('test_file.txt', 'txt')
    subject.grade.save!
    expect expect(subject.url).to match(/.*\/uploads\/grade_file\/file\/#{subject.id}\/\d+_test_file\.txt/)
  end

  it "accepts multiple files" do
    grade.grade_files.new(filename: "test", file: fixture_file('test_file.txt', 'img/jpg'))
    subject.grade.save!
    expect(grade.grade_files.count).to equal 2
  end

  it "has an accessible url" do
    subject.grade.save!
    expect expect(subject.url).to match(/.*\/uploads\/grade_file\/file\/#{subject.id}\/\d+_test_image\.jpg/)
  end

  it "shortens and removes non-word characters from file names on save" do
    subject.file = fixture_file('Too long, strange characters, and Spaces (In) Name.jpg', 'img/jpg')
    subject.grade.save!
    expect expect(subject.url).to match(/.*\/uploads\/grade_file\/file\/#{subject.id}\/\d+_too_long__strange_characters__and_spaces_\.jpg/)
  end

  describe "#course" do
    it 'returns the associated course' do
      expect(subject.course).to eq(course)
    end
  end

  describe "#assignment" do
    it 'returns the associated assignment' do
      expect(subject.assignment).to eq(assignment)
    end
  end

  describe "S3Manager::Carrierwave inclusion" do
    let(:grade_file) { build(:grade_file) }

    it "can be deleted from s3" do
      expect(grade_file.respond_to?(:delete_from_s3)).to be_truthy
    end

    it "can check whether it exists on s3" do
      expect(grade_file.respond_to?(:exists_on_s3?)).to be_truthy
    end
  end
end
