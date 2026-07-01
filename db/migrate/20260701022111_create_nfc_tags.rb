class CreateNfcTags < ActiveRecord::Migration[8.1]
  def change
    create_table :nfc_tags do |t|
      t.string :tag_uid
      t.references :taggable, polymorphic: true, null: false
      t.datetime :written_at
      t.integer :written_by_id

      t.timestamps
    end
    add_index :nfc_tags, :tag_uid, unique: true
  end
end
