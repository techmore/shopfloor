class InventoryTransaction < ApplicationRecord
  belongs_to :part
  belongs_to :reference, polymorphic: true
end
