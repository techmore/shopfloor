class Approval < ApplicationRecord
  belongs_to :approver, class_name: "User", inverse_of: :approvals
  belongs_to :document
  has_paper_trail

  enum :decision, { pending: 0, approved: 1, rejected: 2, changes_requested: 3 }

  validates :document_version, presence: true, numericality: { only_integer: true, greater_than: 0 }

  scope :signed, -> { where.not(signed_at: nil) }

  def signed? = signed_at.present?
end
