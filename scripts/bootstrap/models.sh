#!/bin/bash
# =============================================================================
# models.sh — Generate all models, migrations, and PaperTrail setup
# =============================================================================
set -euo pipefail

APP_DIR="$HOME/$APP_NAME"
cd "$APP_DIR"

echo "=== Installing PaperTrail ==="
rails generate paper_trail:install --with-changes
rails db:migrate

echo "=== Generating models ==="

# --- User (Devise handles this later in auth.sh, we just add fields) ---
# Skipped here — auth.sh runs rails generate devise User

# --- Document models ---
rails generate model Document \
  title:string \
  slug:string:uniq \
  status:integer \
  author:references \
  category:references \
  standard_ref:string \
  document_number:string \
  qr_code:string \
  version:integer

rails generate model Category \
  name:string \
  slug:string:uniq \
  parent:references

rails generate model Comment \
  body:text \
  author:references \
  commentable:references{polymorphic} \
  resolved_at:datetime

rails generate model Approval \
  approver:references \
  document_version:integer \
  decision:integer \
  comment:text \
  signed_at:datetime

# --- Scheduling models ---
rails generate model Shift \
  name:string \
  date:date \
  start_time:time \
  end_time:time \
  station:references

rails generate model WorkStation \
  name:string \
  code:string \
  department:string \
  station_type:integer \
  description:text

rails generate model WorkOrder \
  order_number:string:uniq \
  part:references \
  quantity:integer \
  due_date:date \
  status:integer \
  priority:integer \
  notes:text

rails generate model Assignment \
  shift:references \
  work_order:references \
  worker:references \
  station:references \
  planned_start:datetime \
  planned_end:datetime \
  actual_start:datetime \
  actual_end:datetime \
  notes:text

rails generate model DailyGoal \
  date:date \
  station:references \
  worker:references \
  target_quantity:integer \
  unit:string \
  achieved_quantity:integer

# --- Weigh Station models ---
rails generate model WeighStation \
  name:string \
  code:string \
  has_scale:boolean \
  has_camera:boolean \
  has_printer:boolean \
  has_nfc_reader:boolean \
  ip_address:string \
  scale_type:string \
  printer_model:string

rails generate model WeighSession \
  work_order:references \
  assignment:references \
  part:references \
  worker:references \
  station:references \
  weight_value:decimal \
  unit:string \
  nfc_tag:string \
  printed_label:boolean \
  recorded_at:datetime \
  synced_at:datetime

rails generate model NfcTag \
  tag_uid:string:uniq \
  taggable:references{polymorphic} \
  written_at:datetime \
  written_by:references

rails generate model Shipment \
  shipment_number:string:uniq \
  nfc_tag:references \
  contents:text \
  gross_weight:decimal \
  net_weight:decimal \
  destination:string \
  status:integer

# --- Inventory models ---
rails generate model Part \
  part_number:string:uniq \
  name:string \
  description:text \
  unit:string \
  category:string \
  reorder_point:integer \
  lead_time_days:integer \
  current_stock:integer \
  location:references \
  qr_code:string

rails generate model StockLocation \
  name:string \
  code:string \
  aisle:string \
  rack:string \
  bin:string \
  pos_x:integer \
  pos_y:integer \
  parent:references \
  qr_code:string

rails generate model InventoryTransaction \
  part:references \
  transaction_type:integer \
  quantity:integer \
  reference:references{polymorphic} \
  user:references \
  notes:text \
  timestamp:datetime

rails generate model BillOfMaterial \
  parent_part:references \
  component_part:references \
  quantity_per_assembly:decimal \
  notes:text

# --- Notification ---
rails generate model Notification \
  recipient:references \
  actor:references \
  action:string \
  notifiable:references{polymorphic} \
  read_at:datetime

echo "=== Running migrations ==="
rails db:migrate

echo "=== Done ==="
