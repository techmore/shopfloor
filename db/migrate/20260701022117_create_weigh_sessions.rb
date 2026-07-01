class CreateWeighSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :weigh_sessions do |t|
      t.references :work_order, null: false, foreign_key: true
      t.references :assignment, null: false, foreign_key: true
      t.references :part, null: false, foreign_key: true
      t.integer :worker_id
      t.references :weigh_station, null: false, foreign_key: true
      t.decimal :weight_value
      t.string :unit
      t.string :nfc_tag
      t.boolean :printed_label
      t.datetime :recorded_at
      t.datetime :synced_at

      t.timestamps
    end
  end
end
