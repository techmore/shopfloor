class Shift < ApplicationRecord
  belongs_to :work_station
  has_many :assignments, dependent: :destroy

  validates :name, presence: true
  validates :date, presence: true
  validate :end_after_start

  scope :on, ->(date) { where(date: date) }
  scope :upcoming, -> { where(date: Date.current..).order(:date, :start_time) }

  private

  def end_after_start
    return if start_time.blank? || end_time.blank?

    errors.add(:end_time, "must be after the start time") if end_time <= start_time
  end
end
