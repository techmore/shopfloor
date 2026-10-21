require "rails_helper"

RSpec.describe InventoryTransaction, type: :model do
  subject { build(:inventory_transaction) }

  it { is_expected.to belong_to(:part) }
  it { is_expected.to belong_to(:reference).optional }
  it { is_expected.to belong_to(:user).optional }
  it { is_expected.to define_enum_for(:transaction_type).with_values(receipt: 0, issue: 1, adjustment: 2, transfer: 3, return: 4) }
  it { is_expected.to validate_presence_of(:quantity) }
  it { is_expected.to validate_presence_of(:transaction_type) }

  it "has a valid factory" do
    expect(build(:inventory_transaction)).to be_valid
  end

  it "rejects a zero quantity" do
    expect(build(:inventory_transaction, quantity: 0)).not_to be_valid
    expect(build(:inventory_transaction, quantity: -5, transaction_type: :issue)).to be_valid
  end

  it "can reference the record that caused it" do
    work_order = create(:work_order)
    txn = create(:inventory_transaction, reference: work_order, transaction_type: :issue, quantity: -3)
    expect(txn.reload.reference).to eq(work_order)
    expect(InventoryTransaction.return).to be_empty
  end
end
