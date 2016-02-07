require "active_record_spec_helper"

describe ChallengeFile do
  let(:challenge) { build(:challenge) }

  subject { challenge.challenge_files.new(filename: "test", file: fixture_file('test_image.jpg', 'img/jpg')) }

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
      subject.challenge.save!
      expect(subject.challenge_id).to equal challenge.id
      expect(subject.new_record?).to be_falsey
    end

    it "is deleted when the parent submission is destroyed" do
      subject.challenge.save!
      expect {challenge.destroy}.to change(ChallengeFile, :count).by(-1)
    end
  end

  it "accepts text files as well as images" do
    subject.file = fixture_file('test_file.txt', 'txt')
    subject.challenge.save!
    expect expect(subject.url).to match(/.*\/uploads\/challenge_file\/file\/#{subject.id}\/\d+_test_file\.txt/)
  end

  it "accepts multiple files" do
    challenge.challenge_files.new(filename: "test", file: fixture_file('test_file.txt', 'img/jpg'))
    subject.challenge.save!
    expect(challenge.challenge_files.count).to equal 2
  end

  it "has an accessible url" do
    subject.challenge.save!
    expect expect(subject.url).to match(/.*\/uploads\/challenge_file\/file\/#{subject.id}\/\d+_test_image\.jpg/)
  end

  it "shortens and removes non-word characters from file names on save" do
    subject.file = fixture_file('Too long, strange characters, and Spaces (In) Name.jpg', 'img/jpg')
    subject.challenge.save!
    expect expect(subject.url).to match(/.*\/uploads\/challenge_file\/file\/#{subject.id}\/\d+_too_long__strange_characters__and_spaces_\.jpg/)
  end

  describe "S3Manager::Carrierwave inclusion" do
    let(:challenge_file) { build(:challenge_file) }

    it "can be deleted from s3" do
      expect(challenge_file.respond_to?(:delete_from_s3)).to be_truthy
    end

    it "can check whether it exists on s3" do
      expect(challenge_file.respond_to?(:exists_on_s3?)).to be_truthy
    end
  end
end
