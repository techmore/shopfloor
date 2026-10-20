require "rails_helper"

RSpec.describe WeighSession, type: :model do
  subject { build(:weigh_session) }

  it { is_expected.to belong_to(:work_order) }
  it { is_expected.to belong_to(:assignment).optional }
  it { is_expected.to belong_to(:part) }
  it { is_expected.to belong_to(:weigh_station) }
  it { is_expected.to belong_to(:worker).class_name("User") }
  it { is_expected.to validate_presence_of(:unit) }
  it { is_expected.to validate_numericality_of(:weight_value).is_greater_than(0) }

  it "has a valid factory" do
    expect(build(:weigh_session)).to be_valid
  end

  it "lists unsynced sessions, newest first" do
    older = create(:weigh_session, recorded_at: 2.hours.ago)
    newer = create(:weigh_session, recorded_at: 1.hour.ago)
    create(:weigh_session, synced_at: Time.current)
    expect(WeighSession.unsynced.recent).to eq([ newer, older ])
  end
end
