class CreateBillOfMaterials < ActiveRecord::Migration[8.1]
  def change
    create_table :bill_of_materials do |t|
      t.references :parent_part, null: false, foreign_key: {to_table: :parts}
      t.references :component_part, null: false, foreign_key: {to_table: :parts}
      t.decimal :quantity_per_assembly
      t.text :notes
      t.timestamps
    end
  end
end
