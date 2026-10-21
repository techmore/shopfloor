class Part < ApplicationRecord
  belongs_to :stock_location
  has_many :work_orders, dependent: :restrict_with_error
  has_many :inventory_transactions, dependent: :restrict_with_error
  has_many :weigh_sessions, dependent: :restrict_with_error
  has_many :boms_as_parent, class_name: "BillOfMaterial", foreign_key: :parent_part_id,
           inverse_of: :parent_part, dependent: :destroy
  has_many :boms_as_component, class_name: "BillOfMaterial", foreign_key: :component_part_id,
           inverse_of: :component_part, dependent: :restrict_with_error
  has_many :components, through: :boms_as_parent, source: :component_part

  validates :part_number, presence: true, uniqueness: true
  validates :name, presence: true
  validates :current_stock, :reorder_point, :lead_time_days,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  scope :below_reorder_point, -> { where("current_stock <= reorder_point") }

  # True when stock has fallen to or below the reorder point.
  def needs_reorder?
    return false if current_stock.nil? || reorder_point.nil?

    current_stock <= reorder_point
  end
end
