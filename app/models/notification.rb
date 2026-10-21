class Notification < ApplicationRecord
  belongs_to :recipient, class_name: "User", inverse_of: :notifications_as_recipient
  belongs_to :actor, class_name: "User", optional: true, inverse_of: :notifications_as_actor
  belongs_to :notifiable, polymorphic: true, optional: true

  scope :unread, -> { where(read_at: nil) }
  scope :newest_first, -> { order(created_at: :desc) }

  validates :action, presence: true

  def read? = read_at.present?

  def mark_read!
    update!(read_at: Time.current) unless read?
  end
end
