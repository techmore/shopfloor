class DailyGoal < ApplicationRecord
  belongs_to :work_station
  belongs_to :worker, class_name: "User", optional: true, inverse_of: :daily_goals

  validates :date, presence: true
  validates :target_quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :achieved_quantity, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  scope :on, ->(date) { where(date: date) }

  # Percentage of the target achieved, capped at 100.
  def progress_percent
    return 0 if target_quantity.to_i <= 0

    [ (achieved_quantity.to_i * 100) / target_quantity, 100 ].min
  end

  def achieved?
    achieved_quantity.to_i >= target_quantity.to_i && target_quantity.to_i > 0
  end
end
