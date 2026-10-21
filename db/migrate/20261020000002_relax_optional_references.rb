# Several associations are declared `optional: true` on the models (a weigh session
# recorded outside an assignment, a shipment before an NFC tag is attached, an NFC tag
# that has been written but not yet assigned, an inventory adjustment with no source
# record) but the generated tables carried NOT NULL constraints on those columns, so
# every such record failed with PG::NotNullViolation. Align the database with the models.
class RelaxOptionalReferences < ActiveRecord::Migration[8.1]
  def change
    change_column_null :weigh_sessions, :assignment_id, true
    change_column_null :shipments, :nfc_tag_id, true
    change_column_null :nfc_tags, :taggable_id, true
    change_column_null :nfc_tags, :taggable_type, true
    change_column_null :inventory_transactions, :reference_id, true
    change_column_null :inventory_transactions, :reference_type, true
  end
end
