class WeighStation < ApplicationRecord
  has_many :weigh_sessions, dependent: :restrict_with_error

  validates :name, presence: true
  validates :code, presence: true, uniqueness: true
end
