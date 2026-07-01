class CreateDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :documents do |t|
      t.string :title
      t.string :slug
      t.integer :status
      t.integer :author_id
      t.references :category, null: false, foreign_key: true
      t.string :standard_ref
      t.string :document_number
      t.string :qr_code
      t.integer :version

      t.timestamps
    end
    add_index :documents, :slug, unique: true
  end
end
