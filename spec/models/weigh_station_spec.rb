require "rails_helper"

RSpec.describe WeighStation, type: :model do
  subject { build(:weigh_station) }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:code) }
  it { is_expected.to validate_uniqueness_of(:code) }
  it { is_expected.to have_many(:weigh_sessions).dependent(:restrict_with_error) }

  it "has a valid factory" do
    expect(build(:weigh_station)).to be_valid
  end
end
