require "rails_helper"

RSpec.describe Assignment, type: :model do
  subject { build(:assignment) }

  it { is_expected.to belong_to(:shift) }
  it { is_expected.to belong_to(:work_order) }
  it { is_expected.to belong_to(:work_station) }
  it { is_expected.to belong_to(:worker).class_name("User").optional }
  it { is_expected.to validate_presence_of(:planned_start) }
  it { is_expected.to validate_presence_of(:planned_end) }

  it "has a valid factory" do
    expect(build(:assignment)).to be_valid
  end

  it "rejects a planned end before the planned start" do
    assignment = build(:assignment, planned_start: Time.current, planned_end: Time.current - 1.hour)
    expect(assignment).not_to be_valid
    expect(assignment.errors[:planned_end]).to be_present
  end

  describe "lifecycle" do
    it "derives state from actual timestamps" do
      pending = create(:assignment)
      active = create(:assignment, :started)
      done = create(:assignment, :completed)

      expect(pending).not_to be_started
      expect(active).to be_active
      expect(done).to be_completed
      expect(done).not_to be_active

      expect(Assignment.pending).to contain_exactly(pending)
      expect(Assignment.active).to contain_exactly(active)
      expect(Assignment.completed).to contain_exactly(done)
    end
  end
end
