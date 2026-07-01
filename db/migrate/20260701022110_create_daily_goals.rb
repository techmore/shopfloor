class CreateDailyGoals < ActiveRecord::Migration[8.1]
  def change
    create_table :daily_goals do |t|
      t.date :date
      t.references :work_station, null: false, foreign_key: true
      t.integer :worker_id
      t.integer :target_quantity
      t.string :unit
      t.integer :achieved_quantity

      t.timestamps
    end
  end
end
