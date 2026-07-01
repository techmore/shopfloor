class CreateWorkOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :work_orders do |t|
      t.string :order_number
      t.references :part, null: false, foreign_key: true
      t.integer :quantity
      t.date :due_date
      t.integer :status
      t.integer :priority
      t.text :notes

      t.timestamps
    end
    add_index :work_orders, :order_number, unique: true
  end
end
