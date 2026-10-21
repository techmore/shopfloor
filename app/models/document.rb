class Document < ApplicationRecord
  belongs_to :category
  belongs_to :author, class_name: "User", inverse_of: :documents
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :approvals, dependent: :destroy
  has_paper_trail

  # Lifecycle: draft -> review -> approved -> published -> archived
  enum :status, { draft: 0, review: 1, approved: 2, published: 3, archived: 4 }

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :document_number, uniqueness: true, allow_nil: true
  validates :version, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
end
