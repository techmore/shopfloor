require "rails_helper"

RSpec.describe Part, type: :model do
  subject { build(:part) }

  it { is_expected.to belong_to(:stock_location) }
  it { is_expected.to have_many(:work_orders).dependent(:restrict_with_error) }
  it { is_expected.to have_many(:boms_as_parent).class_name("BillOfMaterial").dependent(:destroy) }
  it { is_expected.to have_many(:components).through(:boms_as_parent) }
  it { is_expected.to validate_presence_of(:part_number) }
  it { is_expected.to validate_uniqueness_of(:part_number) }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_numericality_of(:current_stock).only_integer.is_greater_than_or_equal_to(0).allow_nil }

  it "has a valid factory" do
    expect(build(:part)).to be_valid
  end

  describe "#needs_reorder? / .below_reorder_point" do
    it "flags parts at or below the reorder point" do
      low = create(:part, current_stock: 5, reorder_point: 10)
      at_point = create(:part, current_stock: 10, reorder_point: 10)
      ok = create(:part, current_stock: 50, reorder_point: 10)
      expect(low).to be_needs_reorder
      expect(at_point).to be_needs_reorder
      expect(ok).not_to be_needs_reorder
      expect(Part.below_reorder_point).to contain_exactly(low, at_point)
    end

    it "is false when thresholds are unknown" do
      expect(build(:part, current_stock: nil)).not_to be_needs_reorder
    end
  end

  it "exposes its components through the bill of materials" do
    assembly = create(:part)
    bolt = create(:part)
    create(:bill_of_material, parent_part: assembly, component_part: bolt, quantity_per_assembly: 4)
    expect(assembly.components).to contain_exactly(bolt)
  end
end
