require "rails_helper"

RSpec.describe NfcTag, type: :model do
  subject { build(:nfc_tag) }

  it { is_expected.to belong_to(:taggable).optional }
  it { is_expected.to belong_to(:written_by).class_name("User").optional }
  it { is_expected.to have_many(:shipments).dependent(:restrict_with_error) }
  it { is_expected.to validate_presence_of(:tag_uid) }

  it "has a valid factory" do
    expect(build(:nfc_tag)).to be_valid
  end

  it "normalises the UID and rejects duplicates regardless of case" do
    create(:nfc_tag, tag_uid: " 04a2b3 ")
    duplicate = build(:nfc_tag, tag_uid: "04A2B3")
    expect(duplicate).not_to be_valid
    expect(NfcTag.first.tag_uid).to eq("04A2B3")
  end

  it "can tag any record" do
    part = create(:part)
    tag = create(:nfc_tag, taggable: part)
    expect(tag.reload.taggable).to eq(part)
  end
end
