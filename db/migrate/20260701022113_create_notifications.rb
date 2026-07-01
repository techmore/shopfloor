class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.integer :recipient_id
      t.integer :actor_id
      t.string :action
      t.references :notifiable, polymorphic: true, null: false
      t.datetime :read_at

      t.timestamps
    end
  end
end
