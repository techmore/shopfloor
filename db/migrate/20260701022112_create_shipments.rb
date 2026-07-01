class CreateShipments < ActiveRecord::Migration[8.1]
  def change
    create_table :shipments do |t|
      t.string :shipment_number
      t.references :nfc_tag, null: false, foreign_key: true
      t.text :contents
      t.decimal :gross_weight
      t.decimal :net_weight
      t.string :destination
      t.integer :status

      t.timestamps
    end
    add_index :shipments, :shipment_number, unique: true
  end
end
