class CreateStockLocations < ActiveRecord::Migration[8.1]
  def change
    create_table :stock_locations do |t|
      t.string :name
      t.string :code
      t.string :aisle
      t.string :rack
      t.string :bin
      t.integer :pos_x
      t.integer :pos_y
      t.integer :parent_id
      t.string :qr_code

      t.timestamps
    end
  end
end
