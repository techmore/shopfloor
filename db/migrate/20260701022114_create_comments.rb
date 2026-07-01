class CreateComments < ActiveRecord::Migration[8.1]
  def change
    create_table :comments do |t|
      t.text :body
      t.integer :author_id
      t.references :commentable, polymorphic: true, null: false
      t.datetime :resolved_at

      t.timestamps
    end
  end
end
