class WeighSession < ApplicationRecord
  belongs_to :work_order
  belongs_to :assignment, optional: true
  belongs_to :part
  belongs_to :weigh_station
  belongs_to :worker, class_name: "User", inverse_of: :weigh_sessions
  has_paper_trail

  validates :weight_value, presence: true, numericality: { greater_than: 0 }
  validates :unit, presence: true

  scope :recent, -> { order(recorded_at: :desc, created_at: :desc) }
  scope :unsynced, -> { where(synced_at: nil) }
end
