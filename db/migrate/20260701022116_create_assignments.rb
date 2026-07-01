class CreateAssignments < ActiveRecord::Migration[8.1]
  def change
    create_table :assignments do |t|
      t.references :shift, null: false, foreign_key: true
      t.references :work_order, null: false, foreign_key: true
      t.integer :worker_id
      t.references :work_station, null: false, foreign_key: true
      t.datetime :planned_start
      t.datetime :planned_end
      t.datetime :actual_start
      t.datetime :actual_end
      t.text :notes

      t.timestamps
    end
  end
end
