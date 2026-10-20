class Category < ApplicationRecord
  has_many :documents, dependent: :restrict_with_error
  belongs_to :parent, class_name: "Category", optional: true, inverse_of: :children
  has_many :children, class_name: "Category", foreign_key: :parent_id, inverse_of: :parent,
           dependent: :restrict_with_error

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
end
