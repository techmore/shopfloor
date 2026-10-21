require "rails_helper"

RSpec.describe WorkStation, type: :model do
  subject { build(:work_station) }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:code) }
  it { is_expected.to validate_uniqueness_of(:code) }
  it { is_expected.to define_enum_for(:station_type).with_values(production: 0, assembly: 1, packing: 2, quality: 3, warehouse: 4) }
  it { is_expected.to have_many(:shifts).dependent(:restrict_with_error) }
  it { is_expected.to have_many(:daily_goals).dependent(:restrict_with_error) }
  it { is_expected.to have_many(:assignments).dependent(:restrict_with_error) }

  it "cannot be destroyed while shifts reference it" do
    station = create(:work_station)
    create(:shift, work_station: station)
    expect(station.destroy).to be false
  end
end
