require "active_record_spec_helper"
require "./app/serializers/predicted_assignment_serializer"

describe PredictedAssignmentSerializer do
  let(:assignment) { create :assignment }
  let(:user) { create :user }
  subject { described_class.new assignment, user, user }

  it "responds to any method on the assignment" do
    expect(subject.id).to eq assignment.id
  end

  describe "#grade" do
    it "creates a grade if it does not have one for the assignment" do
      current_time = DateTime.now
      grade = subject.grade
      expect(Grade.find(grade.id).created_at).to be > current_time
    end

    it "returns the grade if one already exists for the user and assignment" do
      existing_grade = Grade.create(assignment: assignment, student: user)
      expect(subject.grade.id).to eq existing_grade.id
    end

    it "returns an instance of a predicted grade" do
      expect(subject.grade).to be_instance_of PredictedGradeSerializer
    end

    it "returns a nil predicted grade if the user cannot create grades" do
      subject = described_class.new assignment, user, NullStudent.new
      expect(subject.grade.id).to eq 0
    end
  end

  describe "#predictor_display_type" do
    it "returns the same type as the assignment" do
      expect(subject.predictor_display_type).to eq(assignment.predictor_display_type)
    end
  end

  describe "#score_levels" do
    it "returns a hash of score levels" do
      subject.assignment_score_levels.build name: "First level", value: 456
      expect(subject.score_levels).to eq([{name: "First level",value: 456}])
    end
  end

  describe "#unlock_conditions" do
    it "returns a list of human readable unlock conditions" do
      uc = build(:unlock_condition)
      allow(assignment).to receive(:unlock_conditions).and_return [uc]
      expect(subject.unlock_conditions).to eq(["#{uc.name} must be #{uc.condition_state}"])
    end
  end

  describe "#unlock_conditions" do
    it "returns a list of human readable unlock conditions" do
      key = build(:unlock_condition)
      allow(assignment).to receive(:unlock_keys).and_return [key]
      expect(subject.unlock_keys).to eq(["#{key.unlockable.name} is unlocked by #{key.condition_state} #{key.condition.name}"])
    end
  end

  describe "#attributes" do
    it "refines the list of exposed attributes" do
      subject = described_class.new assignment, user, user
      exposed_attributes =
      %w( accepts_submissions_until
          assignment_type_id
          description
          due_at
          id
          name
          pass_fail
          point_total
          position )
      expect(exposed_attributes & subject.attributes.keys).to eq(exposed_attributes)
    end

    describe "additional boolean flags" do
      subject { described_class.new( assignment, user, user).attributes }

      describe "is_required" do
        it "is true if assignment.required is true" do
          allow(assignment).to receive(:required).and_return true
          expect(subject[:is_required]).to eq(true)
        end

        it "is false if assignment.required is null" do
          expect(subject[:is_required]).to eq(false)
        end
      end

      describe "has_info" do
        it "is true when assignment has a description" do
          allow(assignment).to receive(:description).and_return "some text"
          expect(subject[:has_info]).to eq(true)
        end

        it "is false if assignment has no description" do
          allow(assignment).to receive(:description).and_return nil
          expect(subject[:has_info]).to eq(false)
        end
      end

      describe "has_rubric" do
        it "is true when assignment has a rubric" do
          allow(assignment).to receive(:has_rubric?).and_return true
          expect(subject[:has_rubric]).to eq(true)
        end

        it "is false if assignment has no rubric" do
          allow(assignment).to receive(:has_rubric?).and_return false
          expect(subject[:has_rubric]).to eq(false)
        end
      end

      describe "accepts_submissions" do
        it "is true when assignment has a rubric" do
          allow(assignment).to receive(:accepts_submissions?).and_return true
          expect(subject[:accepts_submissions]).to eq(true)
        end

        it "is false if assignment has no rubric" do
          allow(assignment).to receive(:accepts_submissions?).and_return false
          expect(subject[:accepts_submissions]).to eq(false)
        end
      end

      describe "is_earned_by_group" do
        it "is true when assignment is a group grade" do
          allow(assignment).to receive(:grade_scope).and_return "Group"
          expect(subject[:is_earned_by_group]).to eq(true)
        end
        it "is false if assignment is an individual grade" do
          allow(assignment).to receive(:grade_scope).and_return "individual"
          expect(subject[:is_earned_by_group]).to eq(false)
        end
      end

      describe "is_late" do
        it "is true when assignment is overdue, accepts submissions, and has no submissions for student" do
          allow(assignment).to receive(:overdue?).and_return true
          allow(assignment).to receive(:accepts_submissions).and_return true
          allow_any_instance_of(User).to receive(:submission_for_assignment).and_return nil
          expect(subject[:is_late]).to eq(true)
        end

        it "is false if assignment is not overdue" do
          allow(assignment).to receive(:overdue?).and_return false
          expect(subject[:is_late]).to eq(false)
        end

        it "is false if assignment is doesn't accept submissions" do
          allow(assignment).to receive(:accepts_submissions).and_return true
          expect(subject[:is_late]).to eq(false)
        end

        it "is false if assignment has a submission" do
          allow_any_instance_of(User).to receive(:submission_for_assignment).and_return true
          expect(subject[:is_late]).to eq(false)
        end
      end

      describe "has_closed" do
        it "is true when the submissions for the assignment have closed" do
          allow(assignment).to receive(:submissions_have_closed?).and_return true
          expect(subject[:has_closed]).to eq(true)
        end

        it "is false if the assignment accepts_submissions in the future" do
          allow(assignment).to receive(:submissions_have_closed?).and_return false
          expect(subject[:has_closed]).to eq(false)
        end
      end

      describe "is_locked" do
        it "is true when assignment is locked for the student" do
          allow(assignment).to receive(:is_unlocked_for_student?).and_return false
          expect(subject[:is_locked]).to eq(true)
        end
        it "is false if assignment is not locked for the student" do
          allow(assignment).to receive(:is_unlocked_for_student?).and_return true
          expect(subject[:is_locked]).to eq(false)
        end
      end

      describe "has_been_unlocked" do
        it "is true when assignment is lockable and has been unlocked" do
          allow(assignment).to receive(:is_unlocked_for_student?).and_return true
          allow(assignment).to receive(:is_unlockable?).and_return true
          expect(subject[:has_been_unlocked]).to eq(true)
        end

        it "is false if assignment is not lockable" do
          allow(assignment).to receive(:is_unlockable?).and_return false
          expect(subject[:has_been_unlocked]).to eq(false)
        end

        it "is false if assignment is locked for student" do
          allow(assignment).to receive(:is_unlocked_for_student?).and_return true
          expect(subject[:has_been_unlocked]).to eq(false)
        end
      end

      describe "is_a_condition" do
        it "is true when assignment is a condition" do
          allow(assignment).to receive(:is_a_condition?).and_return true
          expect(subject[:is_a_condition]).to eq(true)
        end
        it "is false if assignment is not a condition" do
          allow(assignment).to receive(:is_a_condition?).and_return false
          expect(subject[:is_a_condition]).to eq(false)
        end
      end
    end
  end
end

