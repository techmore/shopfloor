#!/bin/bash
# =============================================================================
# setup.sh — THE one script. Run on your Mac. Does EVERYTHING.
# From zero to "rails server" inside a Multipass Ubuntu VM.
#
# Usage:
#   cd /path/to/this/project
#   ./scripts/setup.sh
#
# What it does:
#   1. Installs Multipass if missing (via Homebrew)
#   2. Creates the Ubuntu VM (4 CPU, 8GB RAM, 50GB disk)
#   3. Mounts the project into the VM
#   4. Installs Ruby 3.4.1, Node 22, Postgres, Redis inside the VM
#   5. Creates the Rails app with all models, auth, frontend
#   6. Seeds the database with demo users
#   7. Shows you the URL to open in your browser
# =============================================================================
set -euo pipefail

VM_NAME="shopfloor-dev"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MOUNT_POINT="/home/ubuntu/project"
APP_NAME="shopfloor"
APP_DIR="/home/ubuntu/$APP_NAME"

echo ""
echo "================================================================"
echo "  Shopfloor Operations Platform — Full Setup"
echo "================================================================"
echo ""

# ---- Step 1: Multipass ----
echo "=== [1/7] Checking Multipass ==="
if ! command -v multipass &> /dev/null; then
  echo "Multipass not found. Installing via Homebrew..."
  brew install --cask multipass
  echo "Multipass installed. You may need to enter your password."
else
  echo "Multipass found: $(multipass version | head -1)"
fi

# ---- Step 2: VM ----
echo ""
echo "=== [2/7] Creating VM: $VM_NAME ==="
if multipass list 2>&1 | grep -q "$VM_NAME"; then
  echo "VM '$VM_NAME' already exists. Skipping creation."
else
  echo "Launching Ubuntu 24.04 VM (4 CPU, 8GB RAM, 50GB disk)..."
  multipass launch 24.04 \
    --name "$VM_NAME" \
    --cpus 4 \
    --memory 8G \
    --disk 50G
  echo "VM created."
fi

# ---- Step 3: Mount project ----
echo ""
echo "=== [3/7] Mounting project into VM ==="
if multipass info "$VM_NAME" 2>&1 | grep -q "$MOUNT_POINT"; then
  echo "Project already mounted at $MOUNT_POINT. Skipping."
else
  multipass mount "$PROJECT_DIR" "$VM_NAME:$MOUNT_POINT"
  echo "Mounted $PROJECT_DIR → $VM_NAME:$MOUNT_POINT"
fi

VM_IP=$(multipass info "$VM_NAME" | grep IPv4 | awk '{print $2}')
echo "VM IP: $VM_IP"

# ---- Step 4: VM Bootstrap (system deps) ----
echo ""
echo "=== [4/7] Installing system dependencies in VM ==="
multipass exec "$VM_NAME" -- bash << 'BOOTSTRAP'
  set -euo pipefail

  echo "--- Updating packages ---"
  for attempt in 1 2 3; do
    if sudo apt update && sudo apt upgrade -y; then
      break
    fi
    echo "apt update/upgrade attempt $attempt failed, retrying in 10s..."
    sleep 10
  done

  echo "--- Installing system deps ---"
  for attempt in 1 2 3; do
    if sudo apt install -y \
      curl git build-essential libssl-dev libreadline-dev \
      zlib1g-dev libyaml-dev libxml2-dev libxslt1-dev \
      libpq-dev postgresql postgresql-contrib redis-server \
      imagemagick libsqlite3-dev; then
      break
    fi
    echo "apt install attempt $attempt failed, retrying in 5s..."
    sleep 5
  done

  echo "--- Installing asdf (v0.15.0) ---"
  if [ ! -d "$HOME/.asdf" ]; then
    git clone https://github.com/asdf-vm/asdf.git "$HOME/.asdf" --branch v0.15.0
  fi
  echo '. "$HOME/.asdf/asdf.sh"' >> "$HOME/.bashrc"
  source "$HOME/.asdf/asdf.sh"

  echo "--- Installing Ruby 3.4.1 ---"
  asdf plugin add ruby
  asdf install ruby 3.4.1
  asdf global ruby 3.4.1

  echo "--- Installing Node.js 22 ---"
  asdf plugin add nodejs
  asdf install nodejs 22.14.0
  asdf global nodejs 22.14.0

  echo "--- Installing Rails ---"
  gem install rails bundler

  echo "--- Creating Postgres dev user ---"
  sudo -u postgres createuser -s ubuntu 2>/dev/null || true

  echo "--- System bootstrap complete ---"
BOOTSTRAP

# ---- Step 5: Create Rails app ----
echo ""
echo "=== [5/7] Creating Rails app ==="
multipass exec "$VM_NAME" -- bash -c "
  set -euo pipefail
  source \"\$HOME/.asdf/asdf.sh\"

  if [ -d '$APP_DIR' ]; then
    echo 'Rails app already exists at $APP_DIR. Skipping rails new.'
  else
    echo 'Creating Rails app: $APP_NAME'
    cd /home/ubuntu
    rails new '$APP_NAME' \
      --database=postgresql \
      --css=tailwind \
      --javascript=importmap \
      --skip-test \
      --skip-action-mailbox \
      --skip-action-text
    echo 'Rails app created.'
  fi
"

# ---- Step 6: Bootstrap Rails ----
echo ""
echo "=== [6/7] Running Rails bootstrap phases ==="

# Copy bootstrap scripts into the VM's app directory so they can run from there
multipass exec "$VM_NAME" -- bash -c "mkdir -p $APP_DIR/bootstrap && cp -r $MOUNT_POINT/scripts/bootstrap/* $APP_DIR/bootstrap/"

multipass exec "$VM_NAME" -- bash -c "
  set -euo pipefail
  source \"\$HOME/.asdf/asdf.sh\"

  cd '\$APP_DIR'

  # Phase: Gems
  echo '--- Adding gems ---'
  if ! grep -q 'devise' Gemfile; then
    cat >> Gemfile << 'GEMS'
gem 'devise'
gem 'pundit'
gem 'paper_trail'
gem 'aasm'
gem 'rqrcode'
gem 'pg_search'
gem 'simple_calendar'
gem 'chartkick'
gem 'groupdate'
gem 'kaminari'
gem 'view_component'

group :development, :test do
  gem 'rspec-rails'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'pry-rails'
  gem 'standard'
end

group :development do
  gem 'capistrano', '~> 3.19'
  gem 'capistrano-rails', '~> 1.7'
  gem 'capistrano-bundler', '~> 2.1'
  gem 'capistrano-rvm'
  gem 'foreman'
  gem 'annotate'
  gem 'letter_opener'
end

group :test do
  gem 'shoulda-matchers'
  gem 'cuprite'
  gem 'simplecov', require: false
end
GEMS
  fi

  echo '--- Bundle install ---'
  bundle install

  # Phase: PaperTrail (runs first, no FK deps)
  echo '--- Installing PaperTrail ---'
  rails generate paper_trail:install --with-changes 2>/dev/null || true
  rails db:migrate

  # Phase: Generate all business model tables (user ID columns are integer, no FKs to users yet)
  echo '--- Generating models ---'
  rails generate model WorkStation name:string code:string department:string station_type:integer description:text
  rails generate model Category name:string slug:string:uniq parent_id:integer
  rails generate model StockLocation name:string code:string aisle:string rack:string bin:string pos_x:integer pos_y:integer parent_id:integer qr_code:string
  rails generate model Part part_number:string:uniq name:string description:text unit:string category:string reorder_point:integer lead_time_days:integer current_stock:integer stock_location:references qr_code:string
  rails generate model Document title:string slug:string:uniq status:integer author_id:integer category:references standard_ref:string document_number:string qr_code:string version:integer
  rails generate model Shift name:string date:date start_time:time end_time:time work_station:references
  rails generate model WorkOrder order_number:string:uniq part:references quantity:integer due_date:date status:integer priority:integer notes:text
  rails generate model WeighStation name:string code:string has_scale:boolean has_camera:boolean has_printer:boolean has_nfc_reader:boolean ip_address:string scale_type:string printer_model:string
  rails generate model DailyGoal date:date work_station:references worker_id:integer target_quantity:integer unit:string achieved_quantity:integer
  rails generate model NfcTag tag_uid:string:uniq taggable:references{polymorphic} written_at:datetime written_by_id:integer
  rails generate model Shipment shipment_number:string:uniq nfc_tag:references contents:text gross_weight:decimal net_weight:decimal destination:string status:integer
  rails generate model Notification recipient_id:integer actor_id:integer action:string notifiable:references{polymorphic} read_at:datetime
  rails generate model Comment body:text author_id:integer commentable:references{polymorphic} resolved_at:datetime
  rails generate model Approval approver_id:integer document_version:integer decision:integer comment:text signed_at:datetime
  rails generate model Assignment shift:references work_order:references worker_id:integer work_station:references planned_start:datetime planned_end:datetime actual_start:datetime actual_end:datetime notes:text
  rails generate model WeighSession work_order:references assignment:references part:references worker_id:integer weigh_station:references weight_value:decimal unit:string nfc_tag:string printed_label:boolean recorded_at:datetime synced_at:datetime
  rails generate model InventoryTransaction part:references transaction_type:integer quantity:integer reference:references{polymorphic} user_id:integer notes:text
  rails generate model BillOfMaterial parent_part_id:integer component_part_id:integer quantity_per_assembly:decimal notes:text

  # Fix self-referential FK migrations (parent_id columns referencing own table)
  echo '--- Fixing self-referential FK migrations ---'
  for f in db/migrate/*create_categories.rb; do
    sed -i 's/foreign_key: true/foreign_key: {to_table: :categories}/' \"\$f\"
  done
  for f in db/migrate/*create_stock_locations.rb; do
    sed -i 's/foreign_key: true/foreign_key: {to_table: :stock_locations}/' \"\$f\"
  done
  for f in db/migrate/*create_bill_of_materials.rb; do
    cat > \"\$f\" << BOMFIX
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
BOMFIX
  done
  # Migrate all business tables (timestamps are in gen order, all FKs reference existing tables)
  echo '--- Running business table migrations ---'
  rails db:migrate

  # Phase: Devise + user table
  echo '--- Setting up Devise ---'
  rails generate devise:install
  rails generate devise User role:integer name:string department:string employee_id:string 2>/dev/null || true

  # Overwrite User model with role enum
  echo '--- Writing User model ---'
  cat > app/models/user.rb << 'USERMODEL'
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum :role, { viewer: 0, operator: 1, author: 2, reviewer: 3, approver: 4, scheduler: 5, admin: 6 }
  validates :name, :role, presence: true
  scope :active, -> { where(active: true) }

  def admin?       = role == 'admin'
  def scheduler?   = role == 'scheduler'
  def approver?    = role == 'approver'
  def reviewer?    = role == 'reviewer'
  def author?      = role == 'author'
  def operator?    = role == 'operator'
  def viewer?      = role == 'viewer'
end
USERMODEL
  rails db:migrate

  # Phase: User FK constraints + active column
  echo '--- Adding user FK constraints ---'
  rails generate migration AddUserForeignKeys
  cat > db/migrate/*add_user_foreign_keys.rb << FKMIG
class AddUserForeignKeys < ActiveRecord::Migration[8.1]
  def change
    add_foreign_key :documents, :users, column: :author_id
    add_foreign_key :comments, :users, column: :author_id
    add_foreign_key :approvals, :users, column: :approver_id
    add_foreign_key :assignments, :users, column: :worker_id
    add_foreign_key :daily_goals, :users, column: :worker_id
    add_foreign_key :weigh_sessions, :users, column: :worker_id
    add_foreign_key :nfc_tags, :users, column: :written_by_id
    add_foreign_key :inventory_transactions, :users, column: :user_id
    add_foreign_key :notifications, :users, column: :recipient_id
    add_foreign_key :notifications, :users, column: :actor_id

    add_index :documents, :author_id
    add_index :comments, :author_id
    add_index :approvals, :approver_id
    add_index :assignments, :worker_id
    add_index :daily_goals, :worker_id
    add_index :weigh_sessions, :worker_id
    add_index :nfc_tags, :written_by_id
    add_index :inventory_transactions, :user_id
    add_index :notifications, :recipient_id
    add_index :notifications, :actor_id
  end
end
FKMIG
  rails generate migration AddActiveToUsers active:boolean 2>/dev/null || true
  rails db:migrate

  echo '--- Setting up Pundit ---'
  mkdir -p app/policies
  cat > app/policies/application_policy.rb << 'POLICY'
class ApplicationPolicy
  attr_reader :user, :record
  def initialize(user, record)
    @user = user
    @record = record
  end
  def index? = false
  def show? = false
  def create? = false
  def new? = create?
  def update? = false
  def edit? = update?
  def destroy? = false
  class Scope
    attr_reader :user, :scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end
    def resolve = scope.all
  end
end
POLICY

  # Phase: ApplicationController with Pundit
  echo '--- Writing ApplicationController ---'
  cat > app/controllers/application_controller.rb << 'ACON'
class ApplicationController < ActionController::Base
  include Pundit::Authorization
  before_action :authenticate_user!
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private
  def user_not_authorized
    flash[:alert] = 'You are not authorized.'
    redirect_back(fallback_location: root_path)
  end
end
ACON

  # Phase: Routes (Rails 8: one action per route macro)
  echo '--- Writing routes ---'
  cat > config/routes.rb << 'ROUTES'
Rails.application.routes.draw do
  root 'home#index'

  resources :documents do
    member do
      post :submit
      post :approve
      post :reject
      post :publish
      post :archive
    end
  end
  get 'documents/:id/qr_code', to: 'documents#qr_code', as: :document_qr
  get 'documents/:id/versions', to: 'documents#versions', as: :document_versions
  get 'documents/:id/diff', to: 'documents#diff', as: :document_diff

  get 'schedule', to: 'schedule#index'
  get 'schedule/my', to: 'schedule#my'
  resources :shifts
  resources :work_orders
  resources :assignments do
    member do
      post :start
      post :complete
    end
  end
  resources :work_stations
  resources :daily_goals

  resources :weigh_stations do
    member do
      get :session
    end
  end
  resources :weigh_sessions do
    member do
      post :print_label
    end
  end
  resources :shipments
  post 'nfc_tags/scan', to: 'nfc_tags#scan'

  resources :parts do
    member do
      get :qr_code
    end
  end
  resources :stock_locations do
    member do
      get :qr_code
    end
  end
  resources :inventory_transactions
  resources :bill_of_materials
  resources :categories
  get 'warehouse/map', to: 'warehouse#map'
  get 'warehouse/browse', to: 'warehouse#browse'

  resources :users, only: [:index, :edit, :update]
  get 'qr/batch', to: 'admin#batch_qr'
  get 'audit', to: 'admin#audit_log'

  devise_for :users
end
ROUTES

  # Phase: Views (layout, landing, dashboard, sign-in)
  echo '--- Writing views ---'
  mkdir -p app/views/home app/views/devise/sessions
  npm init -y >/dev/null 2>&1 && npm install daisyui@latest
  rails generate devise:views 2>/dev/null || true
  bash bootstrap/update_views.sh

  # Phase: seed
  echo '--- Seeding database ---'
  cat > db/seeds.rb << 'SEED'
puts 'Seeding...'
unless User.exists?(email: 'admin@shopfloor.local')
  User.create!(email: 'admin@shopfloor.local', password: 'password123', password_confirmation: 'password123', name: 'Admin', role: :admin, department: 'Management', employee_id: 'ADMIN-001', active: true)
  puts '  Created admin: admin@shopfloor.local / password123'
end
[
  { email: 'viewer@shopfloor.local',  name: 'Viewer',   role: :viewer,   department: 'Quality',   employee_id: 'EMP-001' },
  { email: 'operator@shopfloor.local', name: 'Operator', role: :operator, department: 'Production', employee_id: 'EMP-002' },
  { email: 'author@shopfloor.local',   name: 'Author',   role: :author,   department: 'Engineering', employee_id: 'EMP-003' },
  { email: 'reviewer@shopfloor.local', name: 'Reviewer', role: :reviewer, department: 'Quality',   employee_id: 'EMP-004' },
  { email: 'approver@shopfloor.local', name: 'Approver', role: :approver, department: 'Management', employee_id: 'EMP-005' },
  { email: 'scheduler@shopfloor.local',name: 'Scheduler',role: :scheduler,department: 'Production', employee_id: 'EMP-006' },
].each do |u|
  unless User.exists?(email: u[:email])
    User.create!(**u, password: 'password123', password_confirmation: 'password123', active: true)
    puts \"  Created #{u[:role]}: #{u[:email]} / password123\"
  end
end
puts ''
puts 'All passwords: password123'
SEED
  rails db:seed

  echo '--- Bootstrap phases complete ---'
"

# ---- Step 7: Show results ----
echo ""
echo "=== [7/7] Done! ==="
echo ""
echo "================================================================"
echo "  Your Rails app is ready!"
echo "================================================================"
echo ""
echo "  Starting server..."
multipass exec "$VM_NAME" -- bash -c "source \$HOME/.asdf/asdf.sh && cd \$HOME/$APP_NAME && nohup bin/rails server -b 0.0.0.0 -p 3000 &>/tmp/rails.log & disown" 2>/dev/null
sleep 3
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://$VM_IP:3000/" 2>/dev/null || echo "failed")
if [ "$HTTP_CODE" = "200" ]; then
  echo "  Server is live! ✓"
else
  echo "  Server not responding yet — start manually: multipass shell $VM_NAME && cd ~/$APP_NAME && rails server -b 0.0.0.0"
fi
echo ""
echo "  Open in your browser:"
echo "    http://$VM_IP:3000"
echo ""
echo "  Demo accounts (all use password: password123):"
echo "    admin@shopfloor.local   (Admin — full access)"
echo "    scheduler@shopfloor.local (Scheduler)"
echo "    operator@shopfloor.local  (Operator)"
echo "    author@shopfloor.local    (Author)"
echo "    reviewer@shopfloor.local  (Reviewer)"
echo "    approver@shopfloor.local  (Approver)"
echo "    viewer@shopfloor.local    (Viewer)"
echo ""
echo "  Stop the VM when done:"
echo "    multipass stop $VM_NAME"
echo ""
echo "  Rebuild from scratch:"
echo "    multipass delete $VM_NAME && multipass purge"
echo "    ./scripts/setup.sh"
echo "================================================================"
