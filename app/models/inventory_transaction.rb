class InventoryTransaction < ApplicationRecord
  belongs_to :part
  belongs_to :reference, polymorphic: true, optional: true
  belongs_to :user, optional: true
  has_paper_trail

  enum :transaction_type, { receipt: 0, issue: 1, adjustment: 2, transfer: 3, return: 4 }

  validates :quantity, presence: true, numericality: { only_integer: true, other_than: 0 }
  validates :transaction_type, presence: true
end
