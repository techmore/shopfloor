class CreateWorkStations < ActiveRecord::Migration[8.1]
  def change
    create_table :work_stations do |t|
      t.string :name
      t.string :code
      t.string :department
      t.integer :station_type
      t.text :description

      t.timestamps
    end
  end
end
