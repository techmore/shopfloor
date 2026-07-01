class CreateInventoryTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :inventory_transactions do |t|
      t.references :part, null: false, foreign_key: true
      t.integer :transaction_type
      t.integer :quantity
      t.references :reference, polymorphic: true, null: false
      t.integer :user_id
      t.text :notes

      t.timestamps
    end
  end
end
