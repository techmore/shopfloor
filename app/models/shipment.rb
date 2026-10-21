class Shipment < ApplicationRecord
  belongs_to :nfc_tag, optional: true
  has_paper_trail

  enum :status, { created: 0, loading: 1, in_transit: 2, delivered: 3 }

  validates :shipment_number, presence: true, uniqueness: true
  validates :gross_weight, :net_weight, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :net_not_heavier_than_gross

  private

  def net_not_heavier_than_gross
    return if gross_weight.blank? || net_weight.blank?

    errors.add(:net_weight, "cannot exceed the gross weight") if net_weight > gross_weight
  end
end
