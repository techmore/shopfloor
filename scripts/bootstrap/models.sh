#!/bin/bash
set -euo pipefail
source "$HOME/.asdf/asdf.sh"
cd /home/ubuntu/shopfloor

cat > app/models/user.rb << 'RUBY'
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum :role, {
    viewer: 0, operator: 1, author: 2, reviewer: 3,
    approver: 4, scheduler: 5, admin: 6
  }

  has_many :documents, foreign_key: :author_id, dependent: :restrict_with_error
  has_many :comments, foreign_key: :author_id, dependent: :restrict_with_error
  has_many :approvals, foreign_key: :approver_id, dependent: :restrict_with_error
  has_many :assignments, foreign_key: :worker_id, dependent: :restrict_with_error
  has_many :daily_goals, foreign_key: :worker_id, dependent: :restrict_with_error
  has_many :weigh_sessions, foreign_key: :worker_id, dependent: :restrict_with_error
  has_many :nfc_tags, foreign_key: :written_by_id, dependent: :nullify
  has_many :inventory_transactions, foreign_key: :user_id, dependent: :restrict_with_error
  has_many :notifications_as_recipient, class_name: "Notification", foreign_key: :recipient_id, dependent: :destroy
  has_many :notifications_as_actor, class_name: "Notification", foreign_key: :actor_id, dependent: :nullify

  validates :name, presence: true
  validates :role, presence: true
  validates :employee_id, presence: true, uniqueness: true

  scope :active, -> { where(active: true) }

  def admin?       = role == "admin"
  def scheduler?   = role == "scheduler"
  def approver?    = role == "approver"
  def reviewer?    = role == "reviewer"
  def author?      = role == "author"
  def operator?    = role == "operator"
  def viewer?      = role == "viewer"

  def role_at_least?(minimum_role)
    User.roles[role] >= User.roles[minimum_role.to_s]
  end
end
RUBY

cat > app/models/category.rb << 'RUBY'
class Category < ApplicationRecord
  has_many :documents, dependent: :restrict_with_error
  belongs_to :parent, class_name: "Category", optional: true
  has_many :children, class_name: "Category", foreign_key: :parent_id, dependent: :restrict_with_error

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
end
RUBY

cat > app/models/document.rb << 'RUBY'
class Document < ApplicationRecord
  belongs_to :category
  belongs_to :author, class_name: "User"
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :approvals, dependent: :destroy
  has_paper_trail

  enum :status, { draft: 0, review: 1, approved: 2, published: 3, archived: 4 }

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :document_number, presence: true, uniqueness: true, allow_nil: true
end
RUBY

cat > app/models/work_station.rb << 'RUBY'
class WorkStation < ApplicationRecord
  has_many :shifts, dependent: :restrict_with_error
  has_many :daily_goals, dependent: :restrict_with_error
  has_many :assignments, dependent: :restrict_with_error

  enum :station_type, { production: 0, assembly: 1, packing: 2, quality: 3, warehouse: 4 }

  validates :name, presence: true
  validates :code, presence: true, uniqueness: true
end
RUBY

cat > app/models/stock_location.rb << 'RUBY'
class StockLocation < ApplicationRecord
  has_many :parts, dependent: :restrict_with_error
  belongs_to :parent, class_name: "StockLocation", optional: true
  has_many :children, class_name: "StockLocation", foreign_key: :parent_id, dependent: :restrict_with_error

  validates :name, presence: true
  validates :code, presence: true, uniqueness: true
end
RUBY

cat > app/models/part.rb << 'RUBY'
class Part < ApplicationRecord
  belongs_to :stock_location
  has_many :work_orders, dependent: :restrict_with_error
  has_many :inventory_transactions, dependent: :restrict_with_error
  has_many :weigh_sessions, dependent: :restrict_with_error
  has_many :boms_as_parent, class_name: "BillOfMaterial", foreign_key: :parent_part_id, dependent: :destroy
  has_many :boms_as_component, class_name: "BillOfMaterial", foreign_key: :component_part_id, dependent: :restrict_with_error

  validates :part_number, presence: true, uniqueness: true
  validates :name, presence: true
end
RUBY

cat > app/models/shift.rb << 'RUBY'
class Shift < ApplicationRecord
  belongs_to :work_station
  has_many :assignments, dependent: :destroy

  validates :name, presence: true
  validates :date, presence: true
end
RUBY

cat > app/models/work_order.rb << 'RUBY'
class WorkOrder < ApplicationRecord
  belongs_to :part
  has_many :assignments, dependent: :destroy
  has_many :weigh_sessions, dependent: :restrict_with_error

  enum :status, { planned: 0, in_progress: 1, completed: 2, cancelled: 3 }
  enum :priority, { low: 0, normal: 1, high: 2, urgent: 3 }

  validates :order_number, presence: true, uniqueness: true
  validates :quantity, presence: true, numericality: { greater_than: 0 }
end
RUBY

cat > app/models/weigh_station.rb << 'RUBY'
class WeighStation < ApplicationRecord
  has_many :weigh_sessions, dependent: :restrict_with_error

  validates :name, presence: true
  validates :code, presence: true, uniqueness: true
end
RUBY

cat > app/models/weigh_session.rb << 'RUBY'
class WeighSession < ApplicationRecord
  belongs_to :work_order
  belongs_to :assignment, optional: true
  belongs_to :part
  belongs_to :weigh_station
  belongs_to :worker, class_name: "User"
  has_paper_trail

  validates :weight_value, presence: true, numericality: { greater_than: 0 }
  validates :unit, presence: true
end
RUBY

cat > app/models/daily_goal.rb << 'RUBY'
class DailyGoal < ApplicationRecord
  belongs_to :work_station
  belongs_to :worker, class_name: "User", optional: true

  validates :date, presence: true
  validates :target_quantity, presence: true, numericality: { greater_than: 0 }
end
RUBY

cat > app/models/assignment.rb << 'RUBY'
class Assignment < ApplicationRecord
  belongs_to :shift
  belongs_to :work_order
  belongs_to :work_station
  belongs_to :worker, class_name: "User", optional: true
  has_many :weigh_sessions, dependent: :restrict_with_error

  validates :planned_start, presence: true
  validates :planned_end, presence: true
end
RUBY

cat > app/models/nfc_tag.rb << 'RUBY'
class NfcTag < ApplicationRecord
  belongs_to :taggable, polymorphic: true, optional: true
  belongs_to :written_by, class_name: "User", optional: true
  has_many :shipments, dependent: :restrict_with_error

  validates :tag_uid, presence: true, uniqueness: true
end
RUBY

cat > app/models/shipment.rb << 'RUBY'
class Shipment < ApplicationRecord
  belongs_to :nfc_tag, optional: true
  has_paper_trail

  enum :status, { created: 0, loading: 1, in_transit: 2, delivered: 3 }

  validates :shipment_number, presence: true, uniqueness: true
end
RUBY

cat > app/models/bill_of_material.rb << 'RUBY'
class BillOfMaterial < ApplicationRecord
  belongs_to :parent_part, class_name: "Part"
  belongs_to :component_part, class_name: "Part"

  validates :quantity_per_assembly, presence: true, numericality: { greater_than: 0 }
end
RUBY

cat > app/models/inventory_transaction.rb << 'RUBY'
class InventoryTransaction < ApplicationRecord
  belongs_to :part
  belongs_to :reference, polymorphic: true, optional: true
  belongs_to :user, class_name: "User", optional: true
  has_paper_trail

  enum :transaction_type, { receipt: 0, issue: 1, adjustment: 2, transfer: 3, return: 4 }

  validates :quantity, presence: true
end
RUBY

cat > app/models/approval.rb << 'RUBY'
class Approval < ApplicationRecord
  belongs_to :approver, class_name: "User"
  belongs_to :document
  has_paper_trail

  enum :decision, { pending: 0, approved: 1, rejected: 2, changes_requested: 3 }

  validates :document_version, presence: true
end
RUBY

cat > app/models/comment.rb << 'RUBY'
class Comment < ApplicationRecord
  belongs_to :commentable, polymorphic: true
  belongs_to :author, class_name: "User"
  has_paper_trail

  validates :body, presence: true
end
RUBY

cat > app/models/notification.rb << 'RUBY'
class Notification < ApplicationRecord
  belongs_to :recipient, class_name: "User"
  belongs_to :actor, class_name: "User", optional: true
  belongs_to :notifiable, polymorphic: true, optional: true

  scope :unread, -> { where(read_at: nil) }

  validates :action, presence: true
end
RUBY

echo "=== Models updated ==="
