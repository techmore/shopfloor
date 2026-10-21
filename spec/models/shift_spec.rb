require "rails_helper"

RSpec.describe Shift, type: :model do
  subject { build(:shift) }

  it { is_expected.to belong_to(:work_station) }
  it { is_expected.to have_many(:assignments).dependent(:destroy) }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:date) }

  it "has a valid factory" do
    expect(build(:shift)).to be_valid
  end

  it "rejects an end time before the start time" do
    shift = build(:shift, start_time: "16:00", end_time: "08:00")
    expect(shift).not_to be_valid
    expect(shift.errors[:end_time]).to be_present
  end

  describe "scopes" do
    it "filters by date and lists upcoming shifts in order" do
      today = create(:shift, date: Date.current, start_time: "14:00")
      early = create(:shift, date: Date.current, start_time: "06:00")
      create(:shift, date: Date.current - 1)
      tomorrow = create(:shift, date: Date.current + 1)
      expect(Shift.on(Date.current)).to contain_exactly(today, early)
      expect(Shift.upcoming).to eq([ early, today, tomorrow ])
    end
  end
end
