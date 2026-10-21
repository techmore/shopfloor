require "rails_helper"

RSpec.describe Category, type: :model do
  subject { build(:category) }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:slug) }
  it { is_expected.to validate_uniqueness_of(:slug) }
  it { is_expected.to belong_to(:parent).class_name("Category").optional }
  it { is_expected.to have_many(:children).class_name("Category").with_foreign_key(:parent_id) }
  it { is_expected.to have_many(:documents).dependent(:restrict_with_error) }

  it "links parent and children" do
    parent = create(:category)
    child = create(:category, parent: parent)
    expect(parent.children).to contain_exactly(child)
    expect(child.parent).to eq(parent)
  end
end
