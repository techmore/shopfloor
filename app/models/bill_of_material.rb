class BillOfMaterial < ApplicationRecord
  belongs_to :parent_part, class_name: "Part", inverse_of: :boms_as_parent
  belongs_to :component_part, class_name: "Part", inverse_of: :boms_as_component

  validates :quantity_per_assembly, presence: true, numericality: { greater_than: 0 }
  validates :component_part_id, uniqueness: { scope: :parent_part_id, message: "is already on this bill of materials" }
  validate :component_differs_from_parent

  private

  def component_differs_from_parent
    return if parent_part_id.blank? || component_part_id.blank?

    errors.add(:component_part, "cannot be the same as the parent part") if parent_part_id == component_part_id
  end
end
