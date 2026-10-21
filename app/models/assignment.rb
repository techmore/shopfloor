class Assignment < ApplicationRecord
  belongs_to :shift
  belongs_to :work_order
  belongs_to :work_station
  belongs_to :worker, class_name: "User", optional: true, inverse_of: :assignments
  has_many :weigh_sessions, dependent: :restrict_with_error

  validates :planned_start, presence: true
  validates :planned_end, presence: true
  validate :planned_end_after_planned_start

  scope :active, -> { where.not(actual_start: nil).where(actual_end: nil) }
  scope :pending, -> { where(actual_start: nil) }
  scope :completed, -> { where.not(actual_end: nil) }

  def started?   = actual_start.present?
  def completed? = actual_end.present?
  def active?    = started? && !completed?

  private

  def planned_end_after_planned_start
    return if planned_start.blank? || planned_end.blank?

    errors.add(:planned_end, "must be after the planned start") if planned_end <= planned_start
  end
end
