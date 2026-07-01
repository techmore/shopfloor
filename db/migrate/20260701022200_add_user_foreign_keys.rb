class AddUserForeignKeys < ActiveRecord::Migration[8.1]
  def change
    add_foreign_key :documents, :users, column: :author_id
    add_foreign_key :comments, :users, column: :author_id
    add_foreign_key :approvals, :users, column: :approver_id
    add_foreign_key :assignments, :users, column: :worker_id
    add_foreign_key :daily_goals, :users, column: :worker_id
    add_foreign_key :weigh_sessions, :users, column: :worker_id
    add_foreign_key :nfc_tags, :users, column: :written_by_id
    add_foreign_key :inventory_transactions, :users, column: :user_id
    add_foreign_key :notifications, :users, column: :recipient_id
    add_foreign_key :notifications, :users, column: :actor_id

    add_index :documents, :author_id
    add_index :comments, :author_id
    add_index :approvals, :approver_id
    add_index :assignments, :worker_id
    add_index :daily_goals, :worker_id
    add_index :weigh_sessions, :worker_id
    add_index :nfc_tags, :written_by_id
    add_index :inventory_transactions, :user_id
    add_index :notifications, :recipient_id
    add_index :notifications, :actor_id
  end
end
