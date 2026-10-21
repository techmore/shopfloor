require "rails_helper"

RSpec.describe DailyGoal, type: :model do
  subject { build(:daily_goal) }

  it { is_expected.to belong_to(:work_station) }
  it { is_expected.to belong_to(:worker).class_name("User").optional }
  it { is_expected.to validate_presence_of(:date) }
  it { is_expected.to validate_numericality_of(:target_quantity).only_integer.is_greater_than(0) }

  it "has a valid factory" do
    expect(build(:daily_goal)).to be_valid
  end

  describe "#progress_percent" do
    it "reports progress capped at 100" do
      expect(build(:daily_goal, target_quantity: 200, achieved_quantity: 50).progress_percent).to eq(25)
      expect(build(:daily_goal, target_quantity: 10, achieved_quantity: 15).progress_percent).to eq(100)
      expect(build(:daily_goal, target_quantity: 10, achieved_quantity: nil).progress_percent).to eq(0)
    end
  end

  it "knows when it is achieved" do
    expect(build(:daily_goal, target_quantity: 10, achieved_quantity: 10)).to be_achieved
    expect(build(:daily_goal, target_quantity: 10, achieved_quantity: 9)).not_to be_achieved
  end
end
