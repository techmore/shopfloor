class WorkStation < ApplicationRecord
  has_many :shifts, dependent: :restrict_with_error
  has_many :daily_goals, dependent: :restrict_with_error
  has_many :assignments, dependent: :restrict_with_error

  enum :station_type, { production: 0, assembly: 1, packing: 2, quality: 3, warehouse: 4 }

  validates :name, presence: true
  validates :code, presence: true, uniqueness: true
end
