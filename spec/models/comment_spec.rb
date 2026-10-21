require "rails_helper"

RSpec.describe Comment, type: :model do
  subject { build(:comment) }

  it { is_expected.to belong_to(:commentable) }
  it { is_expected.to belong_to(:author).class_name("User") }
  it { is_expected.to validate_presence_of(:body) }

  it "has a valid factory" do
    expect(build(:comment)).to be_valid
  end

  it "can be resolved" do
    comment = create(:comment)
    expect(Comment.unresolved).to include(comment)
    comment.resolve!
    expect(comment).to be_resolved
    expect(Comment.resolved).to contain_exactly(comment)
    expect(Comment.unresolved).to be_empty
  end
end
