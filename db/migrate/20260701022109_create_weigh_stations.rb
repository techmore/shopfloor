class CreateWeighStations < ActiveRecord::Migration[8.1]
  def change
    create_table :weigh_stations do |t|
      t.string :name
      t.string :code
      t.boolean :has_scale
      t.boolean :has_camera
      t.boolean :has_printer
      t.boolean :has_nfc_reader
      t.string :ip_address
      t.string :scale_type
      t.string :printer_model

      t.timestamps
    end
  end
end
