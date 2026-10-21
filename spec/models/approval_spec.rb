require "rails_helper"

RSpec.describe Approval, type: :model do
  subject { build(:approval) }

  it { is_expected.to belong_to(:document) }
  it { is_expected.to belong_to(:approver).class_name("User") }
  it { is_expected.to define_enum_for(:decision).with_values(pending: 0, approved: 1, rejected: 2, changes_requested: 3) }
  it { is_expected.to validate_presence_of(:document_version) }

  it "has a valid factory" do
    expect(build(:approval)).to be_valid
  end

  it "can be attached to a document (regression: approvals had no document_id column)" do
    approval = create(:approval)
    expect(approval.reload.document).to be_a(Document)
    expect(approval.document.approvals).to include(approval)
  end

  describe "#signed? and .signed" do
    it "reflects signed_at" do
      unsigned = create(:approval)
      signed = create(:approval, signed_at: Time.current, decision: :approved)
      expect(unsigned).not_to be_signed
      expect(signed).to be_signed
      expect(Approval.signed).to contain_exactly(signed)
    end
  end
end
