require "rails_helper"

RSpec.describe Notification, type: :model do
  subject { build(:notification) }

  it { is_expected.to belong_to(:recipient).class_name("User") }
  it { is_expected.to belong_to(:actor).class_name("User").optional }
  it { is_expected.to belong_to(:notifiable).optional }
  it { is_expected.to validate_presence_of(:action) }

  it "has a valid factory" do
    expect(build(:notification)).to be_valid
  end

  it "tracks read state" do
    notification = create(:notification)
    expect(Notification.unread).to contain_exactly(notification)
    notification.mark_read!
    expect(notification).to be_read
    expect(Notification.unread).to be_empty
  end

  it "is destroyed with its recipient and kept when its actor is removed" do
    actor = create(:user)
    recipient = create(:user)
    notification = create(:notification, actor: actor, recipient: recipient)
    actor.destroy!
    expect(notification.reload.actor).to be_nil
    expect { recipient.destroy! }.to change(Notification, :count).by(-1)
  end
end
