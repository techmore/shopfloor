class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Roles are ordered from least to most privileged so that `role_at_least?`
  # can compare them numerically.
  enum :role, {
    viewer: 0, operator: 1, author: 2, reviewer: 3,
    approver: 4, scheduler: 5, admin: 6
  }

  has_many :documents, foreign_key: :author_id, inverse_of: :author, dependent: :restrict_with_error
  has_many :comments, foreign_key: :author_id, inverse_of: :author, dependent: :restrict_with_error
  has_many :approvals, foreign_key: :approver_id, inverse_of: :approver, dependent: :restrict_with_error
  has_many :assignments, foreign_key: :worker_id, inverse_of: :worker, dependent: :restrict_with_error
  has_many :daily_goals, foreign_key: :worker_id, inverse_of: :worker, dependent: :restrict_with_error
  has_many :weigh_sessions, foreign_key: :worker_id, inverse_of: :worker, dependent: :restrict_with_error
  has_many :nfc_tags, foreign_key: :written_by_id, inverse_of: :written_by, dependent: :nullify
  has_many :inventory_transactions, dependent: :restrict_with_error
  has_many :notifications_as_recipient, class_name: "Notification", foreign_key: :recipient_id,
           inverse_of: :recipient, dependent: :destroy
  has_many :notifications_as_actor, class_name: "Notification", foreign_key: :actor_id,
           inverse_of: :actor, dependent: :nullify

  validates :name, presence: true
  validates :role, presence: true
  validates :employee_id, uniqueness: true, allow_blank: true

  scope :active, -> { where(active: true) }

  # True when this user's role is at least as privileged as `minimum_role`.
  #
  #   user.role_at_least?(:reviewer)
  def role_at_least?(minimum_role)
    return false if role.blank?

    minimum = self.class.roles.fetch(minimum_role.to_s) do
      raise ArgumentError, "unknown role: #{minimum_role.inspect}"
    end
    self.class.roles.fetch(role) >= minimum
  end
end
