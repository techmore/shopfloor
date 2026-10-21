class WorkOrder < ApplicationRecord
  belongs_to :part
  has_many :assignments, dependent: :destroy
  has_many :weigh_sessions, dependent: :restrict_with_error

  enum :status, { planned: 0, in_progress: 1, completed: 2, cancelled: 3 }
  enum :priority, { low: 0, normal: 1, high: 2, urgent: 3 }

  validates :order_number, presence: true, uniqueness: true
  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }

  scope :open, -> { where(status: [ :planned, :in_progress ]) }
  scope :overdue, -> { open.where(due_date: ...Date.current) }

  def overdue?
    due_date.present? && due_date < Date.current && (planned? || in_progress?)
  end
end
