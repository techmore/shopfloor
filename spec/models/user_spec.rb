require "rails_helper"

RSpec.describe User, type: :model do
  subject { build(:user) }

  it { is_expected.to define_enum_for(:role).with_values(viewer: 0, operator: 1, author: 2, reviewer: 3, approver: 4, scheduler: 5, admin: 6) }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:role) }
  it { is_expected.to validate_uniqueness_of(:employee_id).allow_blank }

  it { is_expected.to have_many(:documents).with_foreign_key(:author_id).dependent(:restrict_with_error) }
  it { is_expected.to have_many(:approvals).with_foreign_key(:approver_id) }
  it { is_expected.to have_many(:assignments).with_foreign_key(:worker_id) }
  it { is_expected.to have_many(:nfc_tags).with_foreign_key(:written_by_id).dependent(:nullify) }
  it { is_expected.to have_many(:notifications_as_recipient).class_name("Notification").dependent(:destroy) }

  it "has a valid factory for every role" do
    User.roles.each_key { |role| expect(build(:user, role: role)).to be_valid }
  end

  describe ".active" do
    it "returns only active users" do
      active = create(:user)
      create(:user, :inactive)
      expect(User.active).to contain_exactly(active)
    end
  end

  describe "#role_at_least?" do
    it "compares roles by privilege order" do
      reviewer = build(:user, :reviewer)
      expect(reviewer.role_at_least?(:viewer)).to be true
      expect(reviewer.role_at_least?(:reviewer)).to be true
      expect(reviewer.role_at_least?("approver")).to be false
      expect(build(:user, :admin).role_at_least?(:scheduler)).to be true
    end

    it "is false without a role" do
      expect(build(:user, role: nil).role_at_least?(:viewer)).to be false
    end

    it "raises on an unknown role name" do
      expect { build(:user).role_at_least?(:superuser) }.to raise_error(ArgumentError, /unknown role/)
    end
  end

  it "accepts symbol roles (as used by db/seeds.rb)" do
    user = create(:user, role: :admin)
    expect(user.reload).to be_admin
  end

  it "cannot be destroyed while it authored documents" do
    author = create(:user, :author)
    create(:document, author: author)
    expect(author.destroy).to be false
    expect(author.errors[:base]).to be_present
  end
end
