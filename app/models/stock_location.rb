class StockLocation < ApplicationRecord
  has_many :parts, dependent: :restrict_with_error
  belongs_to :parent, class_name: "StockLocation", optional: true, inverse_of: :children
  has_many :children, class_name: "StockLocation", foreign_key: :parent_id, inverse_of: :parent,
           dependent: :restrict_with_error

  validates :name, presence: true
  validates :code, presence: true, uniqueness: true
end
