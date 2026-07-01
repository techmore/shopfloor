class CreateShifts < ActiveRecord::Migration[8.1]
  def change
    create_table :shifts do |t|
      t.string :name
      t.date :date
      t.time :start_time
      t.time :end_time
      t.references :work_station, null: false, foreign_key: true

      t.timestamps
    end
  end
end
