class Comment < ApplicationRecord
  belongs_to :commentable, polymorphic: true
  belongs_to :author, class_name: "User", inverse_of: :comments
  has_paper_trail

  validates :body, presence: true

  scope :unresolved, -> { where(resolved_at: nil) }
  scope :resolved, -> { where.not(resolved_at: nil) }

  def resolved? = resolved_at.present?

  def resolve!
    update!(resolved_at: Time.current)
  end
end
