require "light-service"
require "active_record_spec_helper"
require "./app/services/cancels_course_membership/destroys_announcement_states"

describe Services::Actions::DestroysAnnouncementStates do
  let(:course) { membership.course }
  let(:membership) { create :student_course_membership }
  let(:student) { membership.user }

  it "expects the membership to find the announcement states to destroy" do
    expect { described_class.execute }.to \
      raise_error LightService::ExpectedKeysNotInContextError
  end

  it "destroys the announcement states" do
    another_announcement = create :announcement_state, user: student
    course_announcement = create :announcement_state, user: student,
      announcement: create(:announcement, course: course)
    described_class.execute membership: membership
    expect(AnnouncementState.where(user_id: student.id)).to \
      eq [another_announcement]
  end
end
