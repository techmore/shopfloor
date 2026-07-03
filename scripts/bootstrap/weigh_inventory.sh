#!/bin/bash
# =============================================================================
# weigh_inventory.sh — Weigh Stations, Weigh Sessions, Inventory, Shipments
# =============================================================================
set -euo pipefail
source "$HOME/.asdf/asdf.sh"
cd /home/ubuntu/shopfloor

mkdir -p app/policies app/views/weigh_stations app/views/weigh_sessions app/views/parts app/views/stock_locations app/views/bill_of_materials app/views/inventory_transactions app/views/shipments app/views/nfc_tags app/views/warehouse

# ---- Policies ----
cat > app/policies/weigh_station_policy.rb << 'RUBY'
class WeighStationPolicy < ApplicationPolicy
  def index?   = user.operator? || user.scheduler? || user.admin?
  def show?    = index?
  def create?  = user.admin?
  def new?     = create?
  def update?  = user.admin?
  def edit?    = update?
  def destroy? = user.admin?
  def session? = user.operator? || user.admin?
end
RUBY

cat > app/policies/weigh_session_policy.rb << 'RUBY'
class WeighSessionPolicy < ApplicationPolicy
  def index?   = user.operator? || user.scheduler? || user.admin?
  def show?    = index?
  def create?  = user.operator? || user.admin?
  def new?     = create?
  def print_label? = user.operator? || user.admin?
end
RUBY

cat > app/policies/part_policy.rb << 'RUBY'
class PartPolicy < ApplicationPolicy
  def index?   = user.viewer? || user.operator? || user.scheduler? || user.admin?
  def show?    = index?
  def create?  = user.admin?
  def new?     = create?
  def update?  = user.admin?
  def edit?    = update?
  def destroy? = user.admin?
  def qr_code? = true
end
RUBY

cat > app/policies/stock_location_policy.rb << 'RUBY'
class StockLocationPolicy < ApplicationPolicy
  def index?   = user.viewer? || user.operator? || user.admin?
  def show?    = index?
  def create?  = user.admin?
  def new?     = create?
  def update?  = user.admin?
  def edit?    = update?
  def destroy? = user.admin?
  def qr_code? = true
end
RUBY

cat > app/policies/shipment_policy.rb << 'RUBY'
class ShipmentPolicy < ApplicationPolicy
  def index?   = user.operator? || user.admin?
  def show?    = index?
  def create?  = user.operator? || user.admin?
  def new?     = create?
  def update?  = user.operator? || user.admin?
  def edit?    = update?
  def destroy? = user.admin?
end
RUBY

cat > app/policies/bill_of_material_policy.rb << 'RUBY'
class BillOfMaterialPolicy < ApplicationPolicy
  def index?   = user.viewer? || user.admin?
  def show?    = index?
  def create?  = user.admin?
  def new?     = create?
  def update?  = user.admin?
  def edit?    = update?
  def destroy? = user.admin?
end
RUBY

cat > app/policies/inventory_transaction_policy.rb << 'RUBY'
class InventoryTransactionPolicy < ApplicationPolicy
  def index?   = user.operator? || user.admin?
  def show?    = index?
  def create?  = user.operator? || user.admin?
  def new?     = create?
end
RUBY

cat > app/policies/nfc_tag_policy.rb << 'RUBY'
class NfcTagPolicy < ApplicationPolicy
  def index?   = user.operator? || user.admin?
  def show?    = index?
  def create?  = user.operator? || user.admin?
  def new?     = create?
  def scan?    = user.operator? || user.admin?
end
RUBY

cat > app/policies/warehouse_policy.rb << 'RUBY'
class WarehousePolicy < Struct.new(:user, :warehouse)
  def map?   = user.viewer? || user.operator? || user.admin?
  def browse? = map?
end
RUBY

# ---- Controllers ----
cat > app/controllers/weigh_stations_controller.rb << 'RUBY'
class WeighStationsController < ApplicationController
  before_action :set_weigh_station, only: %i[show edit update destroy session]
  after_action :verify_authorized

  def index
    @weigh_stations = policy_scope(WeighStation).order(:name)
  end

  def show
    @sessions = @weigh_station.weigh_sessions.includes(:worker, :part).order(recorded_at: :desc).limit(20)
  end

  def new
    @weigh_station = WeighStation.new
    authorize @weigh_station
  end

  def edit
  end

  def create
    @weigh_station = WeighStation.new(weigh_station_params)
    authorize @weigh_station
    if @weigh_station.save
      redirect_to @weigh_station, notice: "Weigh station created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @weigh_station.update(weigh_station_params)
      redirect_to @weigh_station, notice: "Weigh station updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @weigh_station.destroy!
    redirect_to weigh_stations_path, notice: "Weigh station deleted."
  end

  def session
    @weigh_session = @weigh_station.weigh_sessions.new
    authorize @weigh_station, :session?
  end

  private

  def set_weigh_station
    @weigh_station = WeighStation.find(params[:id])
    authorize @weigh_station
  end

  def weigh_station_params
    params.require(:weigh_station).permit(:name, :code, :has_scale, :has_camera, :has_printer, :has_nfc_reader, :ip_address, :scale_type, :printer_model)
  end
end
RUBY

cat > app/controllers/weigh_sessions_controller.rb << 'RUBY'
class WeighSessionsController < ApplicationController
  before_action :set_weigh_session, only: %i[show print_label]
  after_action :verify_authorized

  def index
    @weigh_sessions = policy_scope(WeighSession).includes(:work_order, :part, :worker, :weigh_station).order(recorded_at: :desc).limit(100)
  end

  def show
  end

  def new
    @weigh_session = WeighSession.new
    @weigh_session.recorded_at = Time.current
    authorize @weigh_session
  end

  def create
    @weigh_session = WeighSession.new(weigh_session_params)
    @weigh_session.worker = current_user
    @weigh_session.recorded_at ||= Time.current
    authorize @weigh_session
    if @weigh_session.save
      redirect_to @weigh_session, notice: "Weight recorded."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def print_label
    redirect_to @weigh_session, notice: "Label sent to printer."
  end

  private

  def set_weigh_session
    @weigh_session = WeighSession.find(params[:id])
    authorize @weigh_session
  end

  def weigh_session_params
    params.require(:weigh_session).permit(:work_order_id, :assignment_id, :part_id, :weigh_station_id, :weight_value, :unit, :nfc_tag, :printed_label)
  end
end
RUBY

cat > app/controllers/parts_controller.rb << 'RUBY'
class PartsController < ApplicationController
  before_action :set_part, only: %i[show edit update destroy qr_code]
  after_action :verify_authorized

  def index
    @parts = policy_scope(Part).includes(:stock_location).order(:part_number)
    if params[:search].present?
      @parts = @parts.where("part_number ILIKE :q OR name ILIKE :q", q: "%#{params[:search]}%")
    end
    @parts = @parts.where(stock_location_id: params[:location_id]) if params[:location_id].present?
  end

  def show
    @inventory_transactions = @part.inventory_transactions.includes(:user).order(created_at: :desc).limit(20)
    @boms_as_parent = @part.boms_as_parent.includes(:component_part)
    @boms_as_component = @part.boms_as_component.includes(:parent_part)
  end

  def new
    @part = Part.new
    authorize @part
  end

  def edit
  end

  def create
    @part = Part.new(part_params)
    authorize @part
    if @part.save
      redirect_to @part, notice: "Part created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @part.update(part_params)
      redirect_to @part, notice: "Part updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @part.destroy!
    redirect_to parts_path, notice: "Part deleted."
  end

  def qr_code
  end

  private

  def set_part
    @part = Part.find(params[:id])
    authorize @part
  end

  def part_params
    params.require(:part).permit(:part_number, :name, :description, :unit, :category, :reorder_point, :lead_time_days, :current_stock, :stock_location_id)
  end
end
RUBY

cat > app/controllers/stock_locations_controller.rb << 'RUBY'
class StockLocationsController < ApplicationController
  before_action :set_stock_location, only: %i[show edit update destroy qr_code]
  after_action :verify_authorized

  def index
    @stock_locations = policy_scope(StockLocation).order(:name)
  end

  def show
    @parts = @stock_location.parts.includes(:stock_location).order(:part_number)
    @children = @stock_location.children.order(:name)
  end

  def new
    @stock_location = StockLocation.new
    authorize @stock_location
  end

  def edit
  end

  def create
    @stock_location = StockLocation.new(stock_location_params)
    authorize @stock_location
    if @stock_location.save
      redirect_to @stock_location, notice: "Location created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @stock_location.update(stock_location_params)
      redirect_to @stock_location, notice: "Location updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @stock_location.destroy!
    redirect_to stock_locations_path, notice: "Location deleted."
  end

  def qr_code
  end

  private

  def set_stock_location
    @stock_location = StockLocation.find(params[:id])
    authorize @stock_location
  end

  def stock_location_params
    params.require(:stock_location).permit(:name, :code, :aisle, :rack, :bin, :pos_x, :pos_y, :parent_id)
  end
end
RUBY

cat > app/controllers/bill_of_materials_controller.rb << 'RUBY'
class BillOfMaterialsController < ApplicationController
  before_action :set_bom, only: %i[show edit update destroy]
  after_action :verify_authorized

  def index
    @bill_of_materials = policy_scope(BillOfMaterial).includes(:parent_part, :component_part).order(:id)
  end

  def show
  end

  def new
    @bill_of_material = BillOfMaterial.new
    authorize @bill_of_material
  end

  def edit
  end

  def create
    @bill_of_material = BillOfMaterial.new(bom_params)
    authorize @bill_of_material
    if @bill_of_material.save
      redirect_to @bill_of_material, notice: "BOM entry created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @bill_of_material.update(bom_params)
      redirect_to @bill_of_material, notice: "BOM entry updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @bill_of_material.destroy!
    redirect_to bill_of_materials_path, notice: "BOM entry deleted."
  end

  private

  def set_bom
    @bill_of_material = BillOfMaterial.find(params[:id])
    authorize @bill_of_material
  end

  def bom_params
    params.require(:bill_of_material).permit(:parent_part_id, :component_part_id, :quantity_per_assembly, :notes)
  end
end
RUBY

cat > app/controllers/inventory_transactions_controller.rb << 'RUBY'
class InventoryTransactionsController < ApplicationController
  before_action :set_transaction, only: %i[show]
  after_action :verify_authorized

  def index
    @transactions = policy_scope(InventoryTransaction).includes(:part, :user).order(created_at: :desc).limit(100)
  end

  def show
  end

  def new
    @transaction = InventoryTransaction.new
    @transaction.user = current_user
    authorize @transaction
  end

  def create
    @transaction = InventoryTransaction.new(transaction_params)
    @transaction.user = current_user
    authorize @transaction
    if @transaction.save
      if @transaction.receipt? || @transaction.return?
        @transaction.part.increment!(:current_stock, @transaction.quantity)
      elsif @transaction.issue?
        @transaction.part.decrement!(:current_stock, @transaction.quantity)
      end
      redirect_to @transaction, notice: "Transaction recorded."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_transaction
    @transaction = InventoryTransaction.find(params[:id])
    authorize @transaction
  end

  def transaction_params
    params.require(:inventory_transaction).permit(:part_id, :transaction_type, :quantity, :notes)
  end
end
RUBY

cat > app/controllers/shipments_controller.rb << 'RUBY'
class ShipmentsController < ApplicationController
  before_action :set_shipment, only: %i[show edit update destroy]
  after_action :verify_authorized

  def index
    @shipments = policy_scope(Shipment).includes(:nfc_tag).order(created_at: :desc)
  end

  def show
  end

  def new
    @shipment = Shipment.new
    authorize @shipment
  end

  def edit
  end

  def create
    @shipment = Shipment.new(shipment_params)
    authorize @shipment
    if @shipment.save
      redirect_to @shipment, notice: "Shipment created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @shipment.update(shipment_params)
      redirect_to @shipment, notice: "Shipment updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @shipment.destroy!
    redirect_to shipments_path, notice: "Shipment deleted."
  end

  private

  def set_shipment
    @shipment = Shipment.find(params[:id])
    authorize @shipment
  end

  def shipment_params
    params.require(:shipment).permit(:shipment_number, :nfc_tag_id, :contents, :gross_weight, :net_weight, :destination, :status)
  end
end
RUBY

cat > app/controllers/nfc_tags_controller.rb << 'RUBY'
class NfcTagsController < ApplicationController
  before_action :set_nfc_tag, only: %i[show]
  after_action :verify_authorized

  def index
    @nfc_tags = policy_scope(NfcTag).includes(:taggable).order(created_at: :desc)
  end

  def show
  end

  def new
    @nfc_tag = NfcTag.new
    @nfc_tag.written_by = current_user
    @nfc_tag.written_at = Time.current
    authorize @nfc_tag
  end

  def create
    @nfc_tag = NfcTag.new(nfc_tag_params)
    @nfc_tag.written_by = current_user
    @nfc_tag.written_at = Time.current
    authorize @nfc_tag
    if @nfc_tag.save
      redirect_to @nfc_tag, notice: "NFC tag registered."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def scan
    @nfc_tag = NfcTag.find_by(tag_uid: params[:uid])
    if @nfc_tag
      redirect_to @nfc_tag
    else
      redirect_to nfc_tags_path, alert: "Tag not found."
    end
  end

  private

  def set_nfc_tag
    @nfc_tag = NfcTag.find(params[:id])
    authorize @nfc_tag
  end

  def nfc_tag_params
    params.require(:nfc_tag).permit(:tag_uid, :taggable_id, :taggable_type)
  end
end
RUBY

cat > app/controllers/warehouse_controller.rb << 'RUBY'
class WarehouseController < ApplicationController
  after_action :verify_authorized

  def map
    authorize :warehouse, :map?
    @stock_locations = StockLocation.includes(:parts).order(:name)
  end

  def browse
    authorize :warehouse, :browse?
    @stock_locations = StockLocation.includes(:parts).order(:name)
  end
end
RUBY

# ---- Views ----
cat > app/views/weigh_stations/index.html.erb << 'ERB'
<div class="flex items-center justify-between mb-6">
  <h1 class="text-2xl font-bold">Weigh Stations</h1>
  <% if policy(WeighStation).create? %><%= link_to "New Station", new_weigh_station_path, class: "btn btn-primary" %><% end %>
</div>
<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
  <% @weigh_stations.each do |ws| %>
    <div class="card bg-base-200 border border-base-300">
      <div class="card-body">
        <h3 class="card-title"><%= link_to ws.name, ws, class: "link link-hover" %></h3>
        <p class="text-sm"><%= ws.code %></p>
        <div class="flex gap-2 text-xs text-base-content/50">
          <span><%= ws.has_scale ? "✓ Scale" : "✗ Scale" %></span>
          <span><%= ws.has_camera ? "✓ Camera" : "✗ Camera" %></span>
          <span><%= ws.has_printer ? "✓ Printer" : "✗ Printer" %></span>
          <span><%= ws.has_nfc_reader ? "✓ NFC" : "✗ NFC" %></span>
        </div>
      </div>
    </div>
  <% end %>
</div>
<% if @weigh_stations.empty? %><div class="text-center py-12 text-base-content/50"><p>No weigh stations.</p></div><% end %>
ERB

cat > app/views/weigh_stations/show.html.erb << 'ERB'
<div class="flex items-center justify-between mb-6">
  <h1 class="text-2xl font-bold"><%= @weigh_station.name %></h1>
  <div class="flex gap-2">
    <% if policy(@weigh_station).session? %><%= link_to "New Session", session_weigh_station_path(@weigh_station), class: "btn btn-primary btn-sm" %><% end %>
    <% if policy(@weigh_station).edit? %><%= link_to "Edit", edit_weigh_station_path(@weigh_station), class: "btn btn-outline btn-sm" %><% end %>
  </div>
</div>
<div class="card bg-base-200 mb-6"><div class="card-body text-sm space-y-2">
  <div class="flex justify-between"><span class="text-base-content/60">Code</span><span><%= @weigh_station.code %></span></div>
  <div class="flex justify-between"><span class="text-base-content/60">Scale</span><span><%= @weigh_station.scale_type.presence || "—" %></span></div>
  <div class="flex justify-between"><span class="text-base-content/60">Printer</span><span><%= @weigh_station.printer_model.presence || "—" %></span></div>
  <div class="flex justify-between"><span class="text-base-content/60">IP</span><span><%= @weigh_station.ip_address || "—" %></span></div>
</div></div>
<h3 class="text-lg font-semibold mb-3">Recent Sessions</h3>
<div class="space-y-2">
  <% @sessions.each do |s| %>
    <div class="card bg-base-200"><div class="card-body py-3"><%= link_to "##{s.id}", s, class: "link link-hover" %> &middot; <%= s.weight_value %> <%= s.unit %> &middot; <%= s.worker&.name %></div></div>
  <% end %>
  <% if @sessions.empty? %><p class="text-sm text-base-content/50">No sessions yet.</p><% end %>
</div>
ERB

cat > app/views/weigh_stations/session.html.erb << 'ERB'
<div class="max-w-lg mx-auto">
  <h1 class="text-2xl font-bold mb-2">Weigh Session</h1>
  <p class="text-base-content/60 mb-6"><%= @weigh_station.name %></p>
  <%= form_with(model: @weigh_session, url: weigh_sessions_path, local: true, class: "space-y-4") do |f| %>
    <%= f.hidden_field :weigh_station_id, value: @weigh_station.id %>
    <div class="form-control"><%= f.label :part_id, class: "label" %><%= f.collection_select :part_id, Part.order(:name), :id, :name, {}, class: "select select-bordered w-full" %></div>
    <div class="form-control"><%= f.label :work_order_id, class: "label" %><%= f.collection_select :work_order_id, WorkOrder.in_progress.order(:order_number), :id, :order_number, { include_blank: true }, class: "select select-bordered w-full" %></div>
    <div class="grid grid-cols-2 gap-4">
      <div class="form-control"><%= f.label :weight_value, class: "label" %><%= f.number_field :weight_value, step: 0.001, class: "input input-bordered w-full" %></div>
      <div class="form-control"><%= f.label :unit, class: "label" %><%= f.text_field :unit, value: "kg", class: "input input-bordered w-full" %></div>
    </div>
    <div class="form-control"><%= f.label :nfc_tag, class: "label" %><%= f.text_field :nfc_tag, class: "input input-bordered w-full", placeholder: "Scan NFC tag..." %></div>
    <div class="form-checkbox"><label class="label cursor-pointer justify-start gap-3"><%= f.check_box :printed_label, class: "checkbox checkbox-primary" %><span class="label-text">Print label</span></label></div>
    <%= f.submit "Record Weight", class: "btn btn-primary w-full" %>
  <% end %>
</div>
ERB

cat > app/views/weigh_sessions/index.html.erb << 'ERB'
<div class="flex items-center justify-between mb-6">
  <h1 class="text-2xl font-bold">Weigh Sessions</h1>
  <% if policy(WeighSession).create? %><%= link_to "New Session", new_weigh_session_path, class: "btn btn-primary" %><% end %>
</div>
<div class="overflow-x-auto">
  <table class="table table-zebra">
    <thead><tr><th>ID</th><th>Part</th><th>Weight</th><th>Unit</th><th>Station</th><th>Worker</th><th>Time</th><th></th></tr></thead>
    <tbody>
      <% @weigh_sessions.each do |s| %>
        <tr>
          <td><%= link_to "##{s.id}", s, class: "link link-hover font-mono" %></td>
          <td><%= s.part&.name %></td>
          <td><%= s.weight_value %></td>
          <td><%= s.unit %></td>
          <td><%= s.weigh_station&.name %></td>
          <td><%= s.worker&.name %></td>
          <td class="text-sm"><%= l s.recorded_at, format: :short %></td>
          <td><%= link_to "View", s, class: "btn btn-ghost btn-xs" %></td>
        </tr>
      <% end %>
    </tbody>
  </table>
</div>
<% if @weigh_sessions.empty? %><div class="text-center py-12 text-base-content/50"><p>No sessions recorded.</p></div><% end %>
ERB

cat > app/views/weigh_sessions/show.html.erb << 'ERB'
<div class="flex items-center justify-between mb-6">
  <h1 class="text-2xl font-bold">Weigh Session #<%= @weigh_session.id %></h1>
  <% if policy(@weigh_session).print_label? %><%= button_to "Print Label", print_label_weigh_session_path(@weigh_session), method: :post, class: "btn btn-outline btn-sm" %><% end %>
</div>
<div class="card bg-base-200"><div class="card-body space-y-2 text-sm">
  <div class="flex justify-between"><span class="text-base-content/60">Part</span><span><%= link_to @weigh_session.part&.name, @weigh_session.part, class: "link link-hover" %></span></div>
  <div class="flex justify-between"><span class="text-base-content/60">Work Order</span><span><%= link_to @weigh_session.work_order&.order_number, @weigh_session.work_order, class: "link link-hover" if @weigh_session.work_order %></span></div>
  <div class="flex justify-between"><span class="text-base-content/60">Weight</span><span class="font-bold text-lg"><%= @weigh_session.weight_value %> <%= @weigh_session.unit %></span></div>
  <div class="flex justify-between"><span class="text-base-content/60">Station</span><span><%= @weigh_session.weigh_station&.name %></span></div>
  <div class="flex justify-between"><span class="text-base-content/60">Worker</span><span><%= @weigh_session.worker&.name %></span></div>
  <div class="flex justify-between"><span class="text-base-content/60">Recorded</span><span><%= l @weigh_session.recorded_at, format: :long %></span></div>
  <div class="flex justify-between"><span class="text-base-content/60">NFC Tag</span><span><%= @weigh_session.nfc_tag.presence || "—" %></span></div>
  <div class="flex justify-between"><span class="text-base-content/60">Printed</span><span><%= @weigh_session.printed_label ? "Yes" : "No" %></span></div>
</div></div>
ERB

cat > app/views/weigh_sessions/new.html.erb << 'ERB'
<div class="max-w-lg mx-auto">
  <h1 class="text-2xl font-bold mb-6">New Weigh Session</h1>
  <%= form_with(model: @weigh_session, local: true, class: "space-y-4") do |f| %>
    <div class="form-control"><%= f.label :weigh_station_id, class: "label" %><%= f.collection_select :weigh_station_id, WeighStation.order(:name), :id, :name, {}, class: "select select-bordered w-full" %></div>
    <div class="form-control"><%= f.label :part_id, class: "label" %><%= f.collection_select :part_id, Part.order(:name), :id, :name, {}, class: "select select-bordered w-full" %></div>
    <div class="form-control"><%= f.label :work_order_id, class: "label" %><%= f.collection_select :work_order_id, WorkOrder.in_progress.order(:order_number), :id, :order_number, { include_blank: true }, class: "select select-bordered w-full" %></div>
    <div class="grid grid-cols-2 gap-4">
      <div class="form-control"><%= f.label :weight_value, class: "label" %><%= f.number_field :weight_value, step: 0.001, class: "input input-bordered w-full" %></div>
      <div class="form-control"><%= f.label :unit, class: "label" %><%= f.text_field :unit, value: "kg", class: "input input-bordered w-full" %></div>
    </div>
    <div class="form-control"><%= f.label :nfc_tag, class: "label" %><%= f.text_field :nfc_tag, class: "input input-bordered w-full" %></div>
    <%= f.submit "Record", class: "btn btn-primary w-full" %>
  <% end %>
</div>
ERB

cat > app/views/parts/index.html.erb << 'ERB'
<div class="flex items-center justify-between mb-6">
  <h1 class="text-2xl font-bold">Parts</h1>
  <% if policy(Part).create? %><%= link_to "New Part", new_part_path, class: "btn btn-primary" %><% end %>
</div>
<div class="flex gap-2 mb-6">
  <%= form_with(url: parts_path, method: :get, local: true, class: "flex gap-2 flex-1") do |f| %>
    <%= f.search_field :search, value: params[:search], placeholder: "Search parts...", class: "input input-bordered w-full max-w-xs" %>
    <%= f.submit "Search", class: "btn btn-ghost btn-sm" %>
  <% end %>
</div>
<div class="overflow-x-auto">
  <table class="table table-zebra">
    <thead><tr><th>Part #</th><th>Name</th><th>Stock</th><th>Location</th><th>Reorder</th><th></th></tr></thead>
    <tbody>
      <% @parts.each do |p| %>
        <tr>
          <td class="font-mono font-medium"><%= link_to p.part_number, p, class: "link link-hover" %></td>
          <td><%= p.name %></td>
          <td><span class="<%= p.current_stock.to_i <= p.reorder_point.to_i ? 'text-error font-bold' : '' %>"><%= p.current_stock %></span></td>
          <td class="text-sm"><%= p.stock_location&.name %></td>
          <td class="text-sm"><%= p.reorder_point %></td>
          <td><%= link_to "View", p, class: "btn btn-ghost btn-xs" %></td>
        </tr>
      <% end %>
    </tbody>
  </table>
</div>
<% if @parts.empty? %><div class="text-center py-12 text-base-content/50"><p>No parts found.</p></div><% end %>
ERB

cat > app/views/parts/show.html.erb << 'ERB'
<div class="flex items-center justify-between mb-6">
  <h1 class="text-2xl font-bold"><%= @part.name %></h1>
  <div class="flex gap-2">
    <span class="badge badge-lg"><%= @part.part_number %></span>
    <% if policy(@part).edit? %><%= link_to "Edit", edit_part_path(@part), class: "btn btn-outline btn-sm" %><% end %>
  </div>
</div>
<div class="grid grid-cols-1 lg:grid-cols-2 gap-4 mb-6">
  <div class="card bg-base-200"><div class="card-body space-y-2 text-sm">
    <div class="flex justify-between"><span class="text-base-content/60">Current Stock</span><span class="font-bold text-lg <%= @part.current_stock.to_i <= @part.reorder_point.to_i ? 'text-error' : '' %>"><%= @part.current_stock %> <%= @part.unit %></span></div>
    <div class="flex justify-between"><span class="text-base-content/60">Reorder Point</span><span><%= @part.reorder_point %></span></div>
    <div class="flex justify-between"><span class="text-base-content/60">Lead Time</span><span><%= @part.lead_time_days %> days</span></div>
    <div class="flex justify-between"><span class="text-base-content/60">Location</span><span><%= @part.stock_location&.name %></span></div>
  </div></div>
  <div class="card bg-base-200"><div class="card-body"><h3 class="card-title text-sm">Description</h3><p class="text-sm text-base-content/60"><%= @part.description.presence || "—" %></p></div></div>
</div>
<div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
  <div><h3 class="text-lg font-semibold mb-3">Transactions</h3><div class="space-y-2">
    <% @inventory_transactions.each do |t| %><div class="card bg-base-200"><div class="card-body py-3 text-sm"><%= t.transaction_type&.titleize %> &middot; <%= t.quantity %> &middot; <%= t.user&.name %></div></div><% end %>
    <% if @inventory_transactions.empty? %><p class="text-sm text-base-content/50">None</p><% end %>
  </div></div>
  <div><h3 class="text-lg font-semibold mb-3">BOM (Parent)</h3><div class="space-y-2">
    <% @boms_as_parent.each do |b| %><div class="card bg-base-200"><div class="card-body py-3 text-sm"><%= b.component_part&.name %> &times; <%= b.quantity_per_assembly %></div></div><% end %>
    <% if @boms_as_parent.empty? %><p class="text-sm text-base-content/50">None</p><% end %>
  </div></div>
  <div><h3 class="text-lg font-semibold mb-3">BOM (Component)</h3><div class="space-y-2">
    <% @boms_as_component.each do |b| %><div class="card bg-base-200"><div class="card-body py-3 text-sm">Used in <%= b.parent_part&.name %> &times; <%= b.quantity_per_assembly %></div></div><% end %>
    <% if @boms_as_component.empty? %><p class="text-sm text-base-content/50">None</p><% end %>
  </div></div>
</div>
ERB

cat > app/views/parts/new.html.erb << 'ERB'
<div class="max-w-lg mx-auto"><h1 class="text-2xl font-bold mb-6">New Part</h1>
<%= form_with(model: @part, local: true, class: "space-y-4") do |f| %>
  <div class="form-control"><%= f.label :part_number, class: "label" %><%= f.text_field :part_number, class: "input input-bordered w-full" %></div>
  <div class="form-control"><%= f.label :name, class: "label" %><%= f.text_field :name, class: "input input-bordered w-full" %></div>
  <div class="form-control"><%= f.label :description, class: "label" %><%= f.text_area :description, rows: 3, class: "textarea textarea-bordered w-full" %></div>
  <div class="grid grid-cols-2 gap-4">
    <div class="form-control"><%= f.label :unit, class: "label" %><%= f.text_field :unit, class: "input input-bordered w-full" %></div>
    <div class="form-control"><%= f.label :stock_location_id, class: "label" %><%= f.collection_select :stock_location_id, StockLocation.order(:name), :id, :name, { include_blank: true }, class: "select select-bordered w-full" %></div>
  </div>
  <div class="grid grid-cols-3 gap-4">
    <div class="form-control"><%= f.label :current_stock, class: "label" %><%= f.number_field :current_stock, class: "input input-bordered w-full" %></div>
    <div class="form-control"><%= f.label :reorder_point, class: "label" %><%= f.number_field :reorder_point, class: "input input-bordered w-full" %></div>
    <div class="form-control"><%= f.label :lead_time_days, class: "label" %><%= f.number_field :lead_time_days, class: "input input-bordered w-full" %></div>
  </div>
  <div class="flex gap-3 pt-2"><%= f.submit class: "btn btn-primary" %><%= link_to "Cancel", parts_path, class: "btn btn-ghost" %></div>
<% end %></div>
ERB

cat > app/views/parts/edit.html.erb << 'ERB'
<div class="max-w-lg mx-auto"><h1 class="text-2xl font-bold mb-6">Edit Part</h1>
<%= form_with(model: @part, local: true, class: "space-y-4") do |f| %>
  <div class="form-control"><%= f.label :part_number, class: "label" %><%= f.text_field :part_number, class: "input input-bordered w-full" %></div>
  <div class="form-control"><%= f.label :name, class: "label" %><%= f.text_field :name, class: "input input-bordered w-full" %></div>
  <div class="form-control"><%= f.label :description, class: "label" %><%= f.text_area :description, rows: 3, class: "textarea textarea-bordered w-full" %></div>
  <div class="grid grid-cols-2 gap-4">
    <div class="form-control"><%= f.label :unit, class: "label" %><%= f.text_field :unit, class: "input input-bordered w-full" %></div>
    <div class="form-control"><%= f.label :stock_location_id, class: "label" %><%= f.collection_select :stock_location_id, StockLocation.order(:name), :id, :name, { include_blank: true }, class: "select select-bordered w-full" %></div>
  </div>
  <div class="grid grid-cols-3 gap-4">
    <div class="form-control"><%= f.label :current_stock, class: "label" %><%= f.number_field :current_stock, class: "input input-bordered w-full" %></div>
    <div class="form-control"><%= f.label :reorder_point, class: "label" %><%= f.number_field :reorder_point, class: "input input-bordered w-full" %></div>
    <div class="form-control"><%= f.label :lead_time_days, class: "label" %><%= f.number_field :lead_time_days, class: "input input-bordered w-full" %></div>
  </div>
  <div class="flex gap-3 pt-2"><%= f.submit class: "btn btn-primary" %><%= link_to "Cancel", @part, class: "btn btn-ghost" %></div>
<% end %></div>
ERB

cat > app/views/stock_locations/index.html.erb << 'ERB'
<div class="flex items-center justify-between mb-6">
  <h1 class="text-2xl font-bold">Stock Locations</h1>
  <% if policy(StockLocation).create? %><%= link_to "New Location", new_stock_location_path, class: "btn btn-primary" %><% end %>
</div>
<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
  <% @stock_locations.each do |sl| %>
    <div class="card bg-base-200 border border-base-300">
      <div class="card-body">
        <h3 class="card-title"><%= link_to sl.name, sl, class: "link link-hover" %></h3>
        <p class="text-sm text-base-content/60"><%= sl.code %> &middot; <%= pluralize(sl.parts.count, "part") %></p>
        <p class="text-xs text-base-content/50"><%= [sl.aisle, sl.rack, sl.bin].compact.join("/") %></p>
      </div>
    </div>
  <% end %>
</div>
<% if @stock_locations.empty? %><div class="text-center py-12 text-base-content/50"><p>No locations.</p></div><% end %>
ERB

cat > app/views/stock_locations/show.html.erb << 'ERB'
<div class="flex items-center justify-between mb-6">
  <h1 class="text-2xl font-bold"><%= @stock_location.name %></h1>
  <% if policy(@stock_location).edit? %><%= link_to "Edit", edit_stock_location_path(@stock_location), class: "btn btn-outline btn-sm" %><% end %>
</div>
<div class="card bg-base-200 mb-6"><div class="card-body space-y-2 text-sm">
  <div class="flex justify-between"><span class="text-base-content/60">Code</span><span><%= @stock_location.code %></span></div>
  <div class="flex justify-between"><span class="text-base-content/60">Position</span><span><%= [@stock_location.aisle, @stock_location.rack, @stock_location.bin].compact.join("/") %></span></div>
  <div class="flex justify-between"><span class="text-base-content/60">Parent</span><span><%= @stock_location.parent&.name || "—" %></span></div>
</div></div>

<% if @children.any? %><div class="mb-6"><h3 class="text-lg font-semibold mb-3">Sub-Locations</h3>
<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-2">
  <% @children.each do |c| %><div class="card bg-base-200"><div class="card-body py-3"><%= link_to c.name, c, class: "link link-hover" %></div></div><% end %>
</div></div><% end %>

<h3 class="text-lg font-semibold mb-3">Parts Here</h3>
<div class="space-y-2">
  <% @parts.each do |p| %><div class="card bg-base-200"><div class="card-body py-3"><%= link_to "#{p.part_number} — #{p.name}", p, class: "link link-hover" %> &middot; Stock: <%= p.current_stock %></div></div><% end %>
  <% if @parts.empty? %><p class="text-sm text-base-content/50">No parts at this location.</p><% end %>
</div>
ERB

cat > app/views/stock_locations/new.html.erb << 'ERB'
<div class="max-w-lg mx-auto"><h1 class="text-2xl font-bold mb-6">New Location</h1>
<%= form_with(model: @stock_location, local: true, class: "space-y-4") do |f| %>
  <div class="form-control"><%= f.label :name, class: "label" %><%= f.text_field :name, class: "input input-bordered w-full" %></div>
  <div class="form-control"><%= f.label :code, class: "label" %><%= f.text_field :code, class: "input input-bordered w-full" %></div>
  <div class="grid grid-cols-3 gap-4">
    <div class="form-control"><%= f.label :aisle, class: "label" %><%= f.text_field :aisle, class: "input input-bordered w-full" %></div>
    <div class="form-control"><%= f.label :rack, class: "label" %><%= f.text_field :rack, class: "input input-bordered w-full" %></div>
    <div class="form-control"><%= f.label :bin, class: "label" %><%= f.text_field :bin, class: "input input-bordered w-full" %></div>
  </div>
  <div class="form-control"><%= f.label :parent_id, class: "label" %><%= f.collection_select :parent_id, StockLocation.order(:name), :id, :name, { include_blank: true }, class: "select select-bordered w-full" %></div>
  <div class="flex gap-3 pt-2"><%= f.submit class: "btn btn-primary" %><%= link_to "Cancel", stock_locations_path, class: "btn btn-ghost" %></div>
<% end %></div>
ERB

cat > app/views/stock_locations/edit.html.erb << 'ERB'
<div class="max-w-lg mx-auto"><h1 class="text-2xl font-bold mb-6">Edit Location</h1>
<%= form_with(model: @stock_location, local: true, class: "space-y-4") do |f| %>
  <div class="form-control"><%= f.label :name, class: "label" %><%= f.text_field :name, class: "input input-bordered w-full" %></div>
  <div class="form-control"><%= f.label :code, class: "label" %><%= f.text_field :code, class: "input input-bordered w-full" %></div>
  <div class="grid grid-cols-3 gap-4">
    <div class="form-control"><%= f.label :aisle, class: "label" %><%= f.text_field :aisle, class: "input input-bordered w-full" %></div>
    <div class="form-control"><%= f.label :rack, class: "label" %><%= f.text_field :rack, class: "input input-bordered w-full" %></div>
    <div class="form-control"><%= f.label :bin, class: "label" %><%= f.text_field :bin, class: "input input-bordered w-full" %></div>
  </div>
  <div class="form-control"><%= f.label :parent_id, class: "label" %><%= f.collection_select :parent_id, StockLocation.order(:name), :id, :name, { include_blank: true }, class: "select select-bordered w-full" %></div>
  <div class="flex gap-3 pt-2"><%= f.submit class: "btn btn-primary" %><%= link_to "Cancel", @stock_location, class: "btn btn-ghost" %></div>
<% end %></div>
ERB

# Remaining CRUD views
cat > app/views/bill_of_materials/index.html.erb << 'ERB'
<div class="flex items-center justify-between mb-6">
  <h1 class="text-2xl font-bold">Bill of Materials</h1>
  <% if policy(BillOfMaterial).create? %><%= link_to "New BOM Entry", new_bill_of_material_path, class: "btn btn-primary" %><% end %>
</div>
<div class="overflow-x-auto">
  <table class="table table-zebra">
    <thead><tr><th>Parent Part</th><th>Component</th><th>Qty/Assembly</th><th></th></tr></thead>
    <tbody>
      <% @bill_of_materials.each do |b| %>
        <tr>
          <td><%= link_to b.parent_part&.name, b, class: "link link-hover" %></td>
          <td><%= b.component_part&.name %></td>
          <td><%= b.quantity_per_assembly %></td>
          <td><%= link_to "View", b, class: "btn btn-ghost btn-xs" %></td>
        </tr>
      <% end %>
    </tbody>
  </table>
</div>
<% if @bill_of_materials.empty? %><div class="text-center py-12 text-base-content/50"><p>No BOM entries.</p></div><% end %>
ERB

cat > app/views/bill_of_materials/show.html.erb << 'ERB'
<div class="flex items-center justify-between mb-6">
  <h1 class="text-2xl font-bold">BOM Entry</h1>
  <% if policy(@bill_of_material).edit? %><%= link_to "Edit", edit_bill_of_material_path(@bill_of_material), class: "btn btn-outline btn-sm" %><% end %>
</div>
<div class="card bg-base-200"><div class="card-body space-y-2 text-sm">
  <div class="flex justify-between"><span class="text-base-content/60">Parent Part</span><span><%= link_to @bill_of_material.parent_part&.name, @bill_of_material.parent_part, class: "link link-hover" %></span></div>
  <div class="flex justify-between"><span class="text-base-content/60">Component</span><span><%= link_to @bill_of_material.component_part&.name, @bill_of_material.component_part, class: "link link-hover" %></span></div>
  <div class="flex justify-between"><span class="text-base-content/60">Qty/Assembly</span><span><%= @bill_of_material.quantity_per_assembly %></span></div>
  <div class="flex justify-between"><span class="text-base-content/60">Notes</span><span><%= @bill_of_material.notes.presence || "—" %></span></div>
</div></div>
ERB

cat > app/views/bill_of_materials/new.html.erb << 'ERB'
<div class="max-w-lg mx-auto"><h1 class="text-2xl font-bold mb-6">New BOM Entry</h1>
<%= form_with(model: @bill_of_material, local: true, class: "space-y-4") do |f| %>
  <div class="form-control"><%= f.label :parent_part_id, class: "label" %><%= f.collection_select :parent_part_id, Part.order(:name), :id, :name, {}, class: "select select-bordered w-full" %></div>
  <div class="form-control"><%= f.label :component_part_id, class: "label" %><%= f.collection_select :component_part_id, Part.order(:name), :id, :name, {}, class: "select select-bordered w-full" %></div>
  <div class="form-control"><%= f.label :quantity_per_assembly, class: "label" %><%= f.number_field :quantity_per_assembly, step: 0.01, class: "input input-bordered w-full" %></div>
  <div class="form-control"><%= f.label :notes, class: "label" %><%= f.text_area :notes, rows: 3, class: "textarea textarea-bordered w-full" %></div>
  <div class="flex gap-3 pt-2"><%= f.submit class: "btn btn-primary" %><%= link_to "Cancel", bill_of_materials_path, class: "btn btn-ghost" %></div>
<% end %></div>
ERB

cat > app/views/bill_of_materials/edit.html.erb << 'ERB'
<div class="max-w-lg mx-auto"><h1 class="text-2xl font-bold mb-6">Edit BOM Entry</h1>
<%= form_with(model: @bill_of_material, local: true, class: "space-y-4") do |f| %>
  <div class="form-control"><%= f.label :parent_part_id, class: "label" %><%= f.collection_select :parent_part_id, Part.order(:name), :id, :name, {}, class: "select select-bordered w-full" %></div>
  <div class="form-control"><%= f.label :component_part_id, class: "label" %><%= f.collection_select :component_part_id, Part.order(:name), :id, :name, {}, class: "select select-bordered w-full" %></div>
  <div class="form-control"><%= f.label :quantity_per_assembly, class: "label" %><%= f.number_field :quantity_per_assembly, step: 0.01, class: "input input-bordered w-full" %></div>
  <div class="form-control"><%= f.label :notes, class: "label" %><%= f.text_area :notes, rows: 3, class: "textarea textarea-bordered w-full" %></div>
  <div class="flex gap-3 pt-2"><%= f.submit class: "btn btn-primary" %><%= link_to "Cancel", @bill_of_material, class: "btn btn-ghost" %></div>
<% end %></div>
ERB

cat > app/views/inventory_transactions/index.html.erb << 'ERB'
<div class="flex items-center justify-between mb-6">
  <h1 class="text-2xl font-bold">Inventory Transactions</h1>
  <% if policy(InventoryTransaction).create? %><%= link_to "New Transaction", new_inventory_transaction_path, class: "btn btn-primary" %><% end %>
</div>
<div class="overflow-x-auto">
  <table class="table table-zebra table-xs">
    <thead><tr><th>Time</th><th>Type</th><th>Part</th><th>Qty</th><th>User</th><th></th></tr></thead>
    <tbody>
      <% @transactions.each do |t| %>
        <tr>
          <td class="text-xs"><%= l t.created_at, format: :short %></td>
          <td><span class="badge badge-sm"><%= t.transaction_type&.titleize %></span></td>
          <td><%= link_to t.part&.name, t.part, class: "link link-hover" %></td>
          <td class="<%= t.issue? ? 'text-error' : 'text-success' %>"><%= t.issue? ? "-#{t.quantity}" : "+#{t.quantity}" %></td>
          <td class="text-xs"><%= t.user&.name %></td>
          <td><%= link_to "View", t, class: "btn btn-ghost btn-xs" %></td>
        </tr>
      <% end %>
    </tbody>
  </table>
</div>
<% if @transactions.empty? %><div class="text-center py-12 text-base-content/50"><p>No transactions.</p></div><% end %>
ERB

cat > app/views/inventory_transactions/show.html.erb << 'ERB'
<h1 class="text-2xl font-bold mb-6">Transaction #<%= @transaction.id %></h1>
<div class="card bg-base-200"><div class="card-body space-y-2 text-sm">
  <div class="flex justify-between"><span class="text-base-content/60">Part</span><span><%= link_to @transaction.part&.name, @transaction.part, class: "link link-hover" %></span></div>
  <div class="flex justify-between"><span class="text-base-content/60">Type</span><span><%= @transaction.transaction_type&.titleize %></span></div>
  <div class="flex justify-between"><span class="text-base-content/60">Quantity</span><span><%= @transaction.quantity %></span></div>
  <div class="flex justify-between"><span class="text-base-content/60">User</span><span><%= @transaction.user&.name %></span></div>
  <div class="flex justify-between"><span class="text-base-content/60">Notes</span><span><%= @transaction.notes.presence || "—" %></span></div>
</div></div>
ERB

cat > app/views/inventory_transactions/new.html.erb << 'ERB'
<div class="max-w-lg mx-auto"><h1 class="text-2xl font-bold mb-6">New Transaction</h1>
<%= form_with(model: @transaction, local: true, class: "space-y-4") do |f| %>
  <div class="form-control"><%= f.label :part_id, class: "label" %><%= f.collection_select :part_id, Part.order(:name), :id, :name, {}, class: "select select-bordered w-full" %></div>
  <div class="form-control"><%= f.label :transaction_type, class: "label" %><%= f.select :transaction_type, InventoryTransaction.transaction_types.keys.map { |t| [t.titleize, t] }, {}, class: "select select-bordered w-full" %></div>
  <div class="form-control"><%= f.label :quantity, class: "label" %><%= f.number_field :quantity, class: "input input-bordered w-full" %></div>
  <div class="form-control"><%= f.label :notes, class: "label" %><%= f.text_area :notes, rows: 3, class: "textarea textarea-bordered w-full" %></div>
  <div class="flex gap-3 pt-2"><%= f.submit class: "btn btn-primary" %><%= link_to "Cancel", inventory_transactions_path, class: "btn btn-ghost" %></div>
<% end %></div>
ERB

cat > app/views/shipments/index.html.erb << 'ERB'
<div class="flex items-center justify-between mb-6">
  <h1 class="text-2xl font-bold">Shipments</h1>
  <% if policy(Shipment).create? %><%= link_to "New Shipment", new_shipment_path, class: "btn btn-primary" %><% end %>
</div>
<div class="overflow-x-auto">
  <table class="table table-zebra">
    <thead><tr><th>Shipment #</th><th>Destination</th><th>Status</th><th>Weight</th><th></th></tr></thead>
    <tbody>
      <% @shipments.each do |s| %>
        <tr>
          <td class="font-mono font-medium"><%= link_to s.shipment_number, s, class: "link link-hover" %></td>
          <td><%= s.destination %></td>
          <td><%= status_badge(s.status) %></td>
          <td><%= s.net_weight %></td>
          <td><%= link_to "View", s, class: "btn btn-ghost btn-xs" %></td>
        </tr>
      <% end %>
    </tbody>
  </table>
</div>
<% if @shipments.empty? %><div class="text-center py-12 text-base-content/50"><p>No shipments.</p></div><% end %>
ERB

cat > app/views/shipments/show.html.erb << 'ERB'
<div class="flex items-center justify-between mb-6">
  <h1 class="text-2xl font-bold">Shipment <%= @shipment.shipment_number %></h1>
  <% if policy(@shipment).edit? %><%= link_to "Edit", edit_shipment_path(@shipment), class: "btn btn-outline btn-sm" %><% end %>
</div>
<div class="card bg-base-200"><div class="card-body space-y-2 text-sm">
  <div class="flex justify-between"><span class="text-base-content/60">Shipment #</span><span><%= @shipment.shipment_number %></span></div>
  <div class="flex justify-between"><span class="text-base-content/60">Status</span><span><%= status_badge(@shipment.status) %></span></div>
  <div class="flex justify-between"><span class="text-base-content/60">Destination</span><span><%= @shipment.destination %></span></div>
  <div class="flex justify-between"><span class="text-base-content/60">Gross Weight</span><span><%= @shipment.gross_weight %></span></div>
  <div class="flex justify-between"><span class="text-base-content/60">Net Weight</span><span><%= @shipment.net_weight %></span></div>
  <div class="flex justify-between"><span class="text-base-content/60">Contents</span><span><%= @shipment.contents %></span></div>
  <div class="flex justify-between"><span class="text-base-content/60">NFC Tag</span><span><%= @shipment.nfc_tag&.tag_uid || "—" %></span></div>
</div></div>
ERB

SHIPMENT_FORM='<%= form_with(model: shipment, local: true, class: "space-y-4") do |f| %>
  <div class="form-control"><%= f.label :shipment_number, class: "label" %><%= f.text_field :shipment_number, class: "input input-bordered w-full" %></div>
  <div class="grid grid-cols-2 gap-4">
    <div class="form-control"><%= f.label :destination, class: "label" %><%= f.text_field :destination, class: "input input-bordered w-full" %></div>
    <div class="form-control"><%= f.label :status, class: "label" %><%= f.select :status, Shipment.statuses.keys.map { |s| [s.titleize, s] }, {}, class: "select select-bordered w-full" %></div>
  </div>
  <div class="grid grid-cols-2 gap-4">
    <div class="form-control"><%= f.label :gross_weight, class: "label" %><%= f.number_field :gross_weight, step: 0.1, class: "input input-bordered w-full" %></div>
    <div class="form-control"><%= f.label :net_weight, class: "label" %><%= f.number_field :net_weight, step: 0.1, class: "input input-bordered w-full" %></div>
  </div>
  <div class="form-control"><%= f.label :contents, class: "label" %><%= f.text_area :contents, rows: 3, class: "textarea textarea-bordered w-full" %></div>
  <div class="form-control"><%= f.label :nfc_tag_id, class: "label" %><%= f.collection_select :nfc_tag_id, NfcTag.order(:tag_uid), :id, :tag_uid, { include_blank: true }, class: "select select-bordered w-full" %></div>
  <div class="flex gap-3 pt-2"><%= f.submit class: "btn btn-primary" %><%= link_to "Cancel", shipment.persisted? ? shipment : shipments_path, class: "btn btn-ghost" %></div>
<% end %>'

cat > app/views/shipments/new.html.erb << ERB
<div class="max-w-lg mx-auto"><h1 class="text-2xl font-bold mb-6">New Shipment</h1>$SHIPMENT_FORM</div>
ERB

cat > app/views/shipments/edit.html.erb << ERB
<div class="max-w-lg mx-auto"><h1 class="text-2xl font-bold mb-6">Edit Shipment</h1>$SHIPMENT_FORM</div>
ERB

cat > app/views/nfc_tags/index.html.erb << 'ERB'
<div class="flex items-center justify-between mb-6">
  <h1 class="text-2xl font-bold">NFC Tags</h1>
  <% if policy(NfcTag).create? %><%= link_to "Register Tag", new_nfc_tag_path, class: "btn btn-primary" %><% end %>
</div>
<div class="overflow-x-auto">
  <table class="table table-zebra">
    <thead><tr><th>Tag UID</th><th>Linked To</th><th>Written By</th><th>Date</th><th></th></tr></thead>
    <tbody>
      <% @nfc_tags.each do |t| %>
        <tr>
          <td class="font-mono"><%= link_to t.tag_uid, t, class: "link link-hover" %></td>
          <td><%= t.taggable_type %> ##{<%= t.taggable_id %>}</td>
          <td><%= t.written_by&.name %></td>
          <td class="text-sm"><%= l t.written_at, format: :short %></td>
          <td><%= link_to "View", t, class: "btn btn-ghost btn-xs" %></td>
        </tr>
      <% end %>
    </tbody>
  </table>
</div>
<% if @nfc_tags.empty? %><div class="text-center py-12 text-base-content/50"><p>No tags registered.</p></div><% end %>
ERB

cat > app/views/nfc_tags/new.html.erb << 'ERB'
<div class="max-w-lg mx-auto"><h1 class="text-2xl font-bold mb-6">Register NFC Tag</h1>
<%= form_with(model: @nfc_tag, local: true, class: "space-y-4") do |f| %>
  <div class="form-control"><%= f.label :tag_uid, class: "label" %><%= f.text_field :tag_uid, class: "input input-bordered w-full", placeholder: "Scan or enter tag UID" %></div>
  <div class="grid grid-cols-2 gap-4">
    <div class="form-control"><%= f.label :taggable_type, class: "label" %><%= f.select :taggable_type, %w[Part Shipment StockLocation], { include_blank: true }, class: "select select-bordered w-full" %></div>
    <div class="form-control"><%= f.label :taggable_id, class: "label" %><%= f.text_field :taggable_id, class: "input input-bordered w-full" %></div>
  </div>
  <div class="flex gap-3 pt-2"><%= f.submit class: "btn btn-primary" %><%= link_to "Cancel", nfc_tags_path, class: "btn btn-ghost" %></div>
<% end %></div>
ERB

cat > app/views/warehouse/map.html.erb << 'ERB'
<h1 class="text-2xl font-bold mb-6">Warehouse Map</h1>
<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
  <% @stock_locations.each do |sl| %>
    <div class="card bg-base-200 border border-base-300">
      <div class="card-body">
        <h3 class="card-title text-sm"><%= link_to sl.name, sl, class: "link link-hover" %></h3>
        <p class="text-xs text-base-content/60"><%= sl.code %> &middot; <%= [sl.aisle, sl.rack, sl.bin].compact.join("/") %></p>
        <p class="text-xs"><%= pluralize(sl.parts.count, "part") %></p>
      </div>
    </div>
  <% end %>
</div>
<% if @stock_locations.empty? %><div class="text-center py-12 text-base-content/50"><p>No locations.</p></div><% end %>
ERB

cat > app/views/warehouse/browse.html.erb << 'ERB'
<h1 class="text-2xl font-bold mb-6">Browse Warehouse</h1>
<div class="overflow-x-auto">
  <table class="table table-zebra">
    <thead><tr><th>Location</th><th>Code</th><th>Parts</th><th>Total Stock</th><th></th></tr></thead>
    <tbody>
      <% @stock_locations.each do |sl| %>
        <tr>
          <td class="font-medium"><%= link_to sl.name, sl, class: "link link-hover" %></td>
          <td><%= sl.code %></td>
          <td><%= sl.parts.count %></td>
          <td><%= sl.parts.sum(:current_stock) %></td>
          <td><%= link_to "View", sl, class: "btn btn-ghost btn-xs" %></td>
        </tr>
      <% end %>
    </tbody>
  </table>
</div>
<% if @stock_locations.empty? %><div class="text-center py-12 text-base-content/50"><p>No locations.</p></div><% end %>
ERB

echo "=== Weigh/Inventory bootstrap complete ==="
