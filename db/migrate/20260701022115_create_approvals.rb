class CreateApprovals < ActiveRecord::Migration[8.1]
  def change
    create_table :approvals do |t|
      t.integer :approver_id
      t.integer :document_version
      t.integer :decision
      t.text :comment
      t.datetime :signed_at

      t.timestamps
    end
  end
end
