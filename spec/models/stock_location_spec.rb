require "rails_helper"

RSpec.describe StockLocation, type: :model do
  subject { build(:stock_location) }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:code) }
  it { is_expected.to validate_uniqueness_of(:code) }
  it { is_expected.to belong_to(:parent).class_name("StockLocation").optional }
  it { is_expected.to have_many(:children).class_name("StockLocation") }
  it { is_expected.to have_many(:parts).dependent(:restrict_with_error) }

  it "nests locations" do
    warehouse = create(:stock_location, name: "Warehouse")
    shelf = create(:stock_location, name: "Shelf", parent: warehouse)
    expect(warehouse.children).to contain_exactly(shelf)
  end
end
