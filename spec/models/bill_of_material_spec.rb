require "rails_helper"

RSpec.describe BillOfMaterial, type: :model do
  subject { build(:bill_of_material) }

  it { is_expected.to belong_to(:parent_part).class_name("Part") }
  it { is_expected.to belong_to(:component_part).class_name("Part") }
  it { is_expected.to validate_presence_of(:quantity_per_assembly) }
  it { is_expected.to validate_numericality_of(:quantity_per_assembly).is_greater_than(0) }

  it "has a valid factory" do
    expect(build(:bill_of_material)).to be_valid
  end

  it "rejects a part as a component of itself" do
    part = create(:part)
    bom = build(:bill_of_material, parent_part: part, component_part: part)
    expect(bom).not_to be_valid
    expect(bom.errors[:component_part]).to be_present
  end

  it "rejects the same component twice on one assembly" do
    existing = create(:bill_of_material)
    duplicate = build(:bill_of_material, parent_part: existing.parent_part, component_part: existing.component_part)
    expect(duplicate).not_to be_valid
  end
end
