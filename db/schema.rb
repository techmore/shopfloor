# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_07_01_022202) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "approvals", force: :cascade do |t|
    t.integer "approver_id"
    t.text "comment"
    t.datetime "created_at", null: false
    t.integer "decision"
    t.integer "document_version"
    t.datetime "signed_at"
    t.datetime "updated_at", null: false
    t.index ["approver_id"], name: "index_approvals_on_approver_id"
  end

  create_table "assignments", force: :cascade do |t|
    t.datetime "actual_end"
    t.datetime "actual_start"
    t.datetime "created_at", null: false
    t.text "notes"
    t.datetime "planned_end"
    t.datetime "planned_start"
    t.bigint "shift_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "work_order_id", null: false
    t.bigint "work_station_id", null: false
    t.integer "worker_id"
    t.index ["shift_id"], name: "index_assignments_on_shift_id"
    t.index ["work_order_id"], name: "index_assignments_on_work_order_id"
    t.index ["work_station_id"], name: "index_assignments_on_work_station_id"
    t.index ["worker_id"], name: "index_assignments_on_worker_id"
  end

  create_table "bill_of_materials", force: :cascade do |t|
    t.bigint "component_part_id", null: false
    t.datetime "created_at", null: false
    t.text "notes"
    t.bigint "parent_part_id", null: false
    t.decimal "quantity_per_assembly"
    t.datetime "updated_at", null: false
    t.index ["component_part_id"], name: "index_bill_of_materials_on_component_part_id"
    t.index ["parent_part_id"], name: "index_bill_of_materials_on_parent_part_id"
  end

  create_table "categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.integer "parent_id"
    t.string "slug"
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_categories_on_slug", unique: true
  end

  create_table "comments", force: :cascade do |t|
    t.integer "author_id"
    t.text "body"
    t.bigint "commentable_id", null: false
    t.string "commentable_type", null: false
    t.datetime "created_at", null: false
    t.datetime "resolved_at"
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_comments_on_author_id"
    t.index ["commentable_type", "commentable_id"], name: "index_comments_on_commentable"
  end

  create_table "daily_goals", force: :cascade do |t|
    t.integer "achieved_quantity"
    t.datetime "created_at", null: false
    t.date "date"
    t.integer "target_quantity"
    t.string "unit"
    t.datetime "updated_at", null: false
    t.bigint "work_station_id", null: false
    t.integer "worker_id"
    t.index ["work_station_id"], name: "index_daily_goals_on_work_station_id"
    t.index ["worker_id"], name: "index_daily_goals_on_worker_id"
  end

  create_table "documents", force: :cascade do |t|
    t.integer "author_id"
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.string "document_number"
    t.string "qr_code"
    t.string "slug"
    t.string "standard_ref"
    t.integer "status"
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "version"
    t.index ["author_id"], name: "index_documents_on_author_id"
    t.index ["category_id"], name: "index_documents_on_category_id"
    t.index ["slug"], name: "index_documents_on_slug", unique: true
  end

  create_table "inventory_transactions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "notes"
    t.bigint "part_id", null: false
    t.integer "quantity"
    t.bigint "reference_id", null: false
    t.string "reference_type", null: false
    t.integer "transaction_type"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["part_id"], name: "index_inventory_transactions_on_part_id"
    t.index ["reference_type", "reference_id"], name: "index_inventory_transactions_on_reference"
    t.index ["user_id"], name: "index_inventory_transactions_on_user_id"
  end

  create_table "nfc_tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "tag_uid"
    t.bigint "taggable_id", null: false
    t.string "taggable_type", null: false
    t.datetime "updated_at", null: false
    t.datetime "written_at"
    t.integer "written_by_id"
    t.index ["tag_uid"], name: "index_nfc_tags_on_tag_uid", unique: true
    t.index ["taggable_type", "taggable_id"], name: "index_nfc_tags_on_taggable"
    t.index ["written_by_id"], name: "index_nfc_tags_on_written_by_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.string "action"
    t.integer "actor_id"
    t.datetime "created_at", null: false
    t.bigint "notifiable_id", null: false
    t.string "notifiable_type", null: false
    t.datetime "read_at"
    t.integer "recipient_id"
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_notifications_on_actor_id"
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable"
    t.index ["recipient_id"], name: "index_notifications_on_recipient_id"
  end

  create_table "parts", force: :cascade do |t|
    t.string "category"
    t.datetime "created_at", null: false
    t.integer "current_stock"
    t.text "description"
    t.integer "lead_time_days"
    t.string "name"
    t.string "part_number"
    t.string "qr_code"
    t.integer "reorder_point"
    t.bigint "stock_location_id", null: false
    t.string "unit"
    t.datetime "updated_at", null: false
    t.index ["part_number"], name: "index_parts_on_part_number", unique: true
    t.index ["stock_location_id"], name: "index_parts_on_stock_location_id"
  end

  create_table "shifts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date"
    t.time "end_time"
    t.string "name"
    t.time "start_time"
    t.datetime "updated_at", null: false
    t.bigint "work_station_id", null: false
    t.index ["work_station_id"], name: "index_shifts_on_work_station_id"
  end

  create_table "shipments", force: :cascade do |t|
    t.text "contents"
    t.datetime "created_at", null: false
    t.string "destination"
    t.decimal "gross_weight"
    t.decimal "net_weight"
    t.bigint "nfc_tag_id", null: false
    t.string "shipment_number"
    t.integer "status"
    t.datetime "updated_at", null: false
    t.index ["nfc_tag_id"], name: "index_shipments_on_nfc_tag_id"
    t.index ["shipment_number"], name: "index_shipments_on_shipment_number", unique: true
  end

  create_table "stock_locations", force: :cascade do |t|
    t.string "aisle"
    t.string "bin"
    t.string "code"
    t.datetime "created_at", null: false
    t.string "name"
    t.integer "parent_id"
    t.integer "pos_x"
    t.integer "pos_y"
    t.string "qr_code"
    t.string "rack"
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.boolean "active"
    t.datetime "created_at", null: false
    t.string "department"
    t.string "email", default: "", null: false
    t.string "employee_id"
    t.string "encrypted_password", default: "", null: false
    t.string "name"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.datetime "created_at"
    t.string "event", null: false
    t.bigint "item_id", null: false
    t.string "item_type", null: false
    t.text "object"
    t.text "object_changes"
    t.string "whodunnit"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "weigh_sessions", force: :cascade do |t|
    t.bigint "assignment_id", null: false
    t.datetime "created_at", null: false
    t.string "nfc_tag"
    t.bigint "part_id", null: false
    t.boolean "printed_label"
    t.datetime "recorded_at"
    t.datetime "synced_at"
    t.string "unit"
    t.datetime "updated_at", null: false
    t.bigint "weigh_station_id", null: false
    t.decimal "weight_value"
    t.bigint "work_order_id", null: false
    t.integer "worker_id"
    t.index ["assignment_id"], name: "index_weigh_sessions_on_assignment_id"
    t.index ["part_id"], name: "index_weigh_sessions_on_part_id"
    t.index ["weigh_station_id"], name: "index_weigh_sessions_on_weigh_station_id"
    t.index ["work_order_id"], name: "index_weigh_sessions_on_work_order_id"
    t.index ["worker_id"], name: "index_weigh_sessions_on_worker_id"
  end

  create_table "weigh_stations", force: :cascade do |t|
    t.string "code"
    t.datetime "created_at", null: false
    t.boolean "has_camera"
    t.boolean "has_nfc_reader"
    t.boolean "has_printer"
    t.boolean "has_scale"
    t.string "ip_address"
    t.string "name"
    t.string "printer_model"
    t.string "scale_type"
    t.datetime "updated_at", null: false
  end

  create_table "work_orders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "due_date"
    t.text "notes"
    t.string "order_number"
    t.bigint "part_id", null: false
    t.integer "priority"
    t.integer "quantity"
    t.integer "status"
    t.datetime "updated_at", null: false
    t.index ["order_number"], name: "index_work_orders_on_order_number", unique: true
    t.index ["part_id"], name: "index_work_orders_on_part_id"
  end

  create_table "work_stations", force: :cascade do |t|
    t.string "code"
    t.datetime "created_at", null: false
    t.string "department"
    t.text "description"
    t.string "name"
    t.integer "station_type"
    t.datetime "updated_at", null: false
  end

  add_foreign_key "approvals", "users", column: "approver_id"
  add_foreign_key "assignments", "shifts"
  add_foreign_key "assignments", "users", column: "worker_id"
  add_foreign_key "assignments", "work_orders"
  add_foreign_key "assignments", "work_stations"
  add_foreign_key "bill_of_materials", "parts", column: "component_part_id"
  add_foreign_key "bill_of_materials", "parts", column: "parent_part_id"
  add_foreign_key "comments", "users", column: "author_id"
  add_foreign_key "daily_goals", "users", column: "worker_id"
  add_foreign_key "daily_goals", "work_stations"
  add_foreign_key "documents", "categories"
  add_foreign_key "documents", "users", column: "author_id"
  add_foreign_key "inventory_transactions", "parts"
  add_foreign_key "inventory_transactions", "users"
  add_foreign_key "nfc_tags", "users", column: "written_by_id"
  add_foreign_key "notifications", "users", column: "actor_id"
  add_foreign_key "notifications", "users", column: "recipient_id"
  add_foreign_key "parts", "stock_locations"
  add_foreign_key "shifts", "work_stations"
  add_foreign_key "shipments", "nfc_tags"
  add_foreign_key "weigh_sessions", "assignments"
  add_foreign_key "weigh_sessions", "parts"
  add_foreign_key "weigh_sessions", "users", column: "worker_id"
  add_foreign_key "weigh_sessions", "weigh_stations"
  add_foreign_key "weigh_sessions", "work_orders"
  add_foreign_key "work_orders", "parts"
end
