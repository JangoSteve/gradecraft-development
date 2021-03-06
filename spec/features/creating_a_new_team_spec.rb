require "rails_spec_helper"

feature "creating a new team" do
  context "as a professor" do
    let(:course) { create :course, team_setting: true}
    let!(:course_membership) { create :professor_course_membership, user: professor, course: course }
    let(:professor) { create :user }

    before(:each) do
      login_as professor
      visit dashboard_path
    end

    scenario "successfully" do
      within(".sidebar-container") do
        click_link "teams"
      end

      within(".context_menu") do
        click_link "New Team"
      end

      expect(current_path).to eq new_team_path

      within(".pageContent") do
        fill_in "Name", with: "New Team Name"
        click_button "Create team"
      end

      expect(page).to have_notification_message('notice', 'Team New Team Name successfully created')
    end
  end
end
