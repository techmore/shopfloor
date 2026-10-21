require "rails_helper"

RSpec.describe Document, type: :model do
  subject { build(:document) }

  it { is_expected.to belong_to(:category) }
  it { is_expected.to belong_to(:author).class_name("User") }
  it { is_expected.to have_many(:comments).dependent(:destroy) }
  it { is_expected.to have_many(:approvals).dependent(:destroy) }
  it { is_expected.to define_enum_for(:status).with_values(draft: 0, review: 1, approved: 2, published: 3, archived: 4) }
  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:slug) }
  it { is_expected.to validate_uniqueness_of(:slug) }
  it { is_expected.to validate_uniqueness_of(:document_number).allow_nil }

  it "has a valid factory" do
    expect(build(:document)).to be_valid
  end

  it "rejects a non-positive version" do
    expect(build(:document, version: 0)).not_to be_valid
  end

  it "records versions with PaperTrail" do
    document = nil
    PaperTrail.request(enabled: true) do
      document = create(:document, title: "v1")
      document.update!(title: "v2")
    end
    expect(document.versions.count).to eq(2)
  end

  it "destroys dependent comments and approvals" do
    document = create(:document)
    create(:comment, commentable: document)
    create(:approval, document: document)
    expect { document.destroy! }.to change(Comment, :count).by(-1).and change(Approval, :count).by(-1)
  end
end
