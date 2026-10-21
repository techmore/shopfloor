require "rails_helper"

RSpec.describe Shipment, type: :model do
  subject { build(:shipment) }

  it { is_expected.to belong_to(:nfc_tag).optional }
  it { is_expected.to define_enum_for(:status).with_values(created: 0, loading: 1, in_transit: 2, delivered: 3) }
  it { is_expected.to validate_presence_of(:shipment_number) }
  it { is_expected.to validate_uniqueness_of(:shipment_number) }

  it "has a valid factory" do
    expect(build(:shipment)).to be_valid
  end

  it "rejects a net weight above the gross weight" do
    shipment = build(:shipment, gross_weight: 10, net_weight: 11)
    expect(shipment).not_to be_valid
    expect(shipment.errors[:net_weight]).to be_present
  end

  it "exposes enum scopes for every status" do
    shipment = create(:shipment, status: :in_transit)
    expect(Shipment.in_transit).to contain_exactly(shipment)
    expect(Shipment.created).to be_empty
  end
end
