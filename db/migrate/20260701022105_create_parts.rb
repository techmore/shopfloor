class CreateParts < ActiveRecord::Migration[8.1]
  def change
    create_table :parts do |t|
      t.string :part_number
      t.string :name
      t.text :description
      t.string :unit
      t.string :category
      t.integer :reorder_point
      t.integer :lead_time_days
      t.integer :current_stock
      t.references :stock_location, null: false, foreign_key: true
      t.string :qr_code

      t.timestamps
    end
    add_index :parts, :part_number, unique: true
  end
end
