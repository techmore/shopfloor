#!/bin/bash
# =============================================================================
# admin.sh — Admin controllers, User management, Audit log, Dashboard
# =============================================================================
set -euo pipefail
source "$HOME/.asdf/asdf.sh"
cd /home/ubuntu/shopfloor

mkdir -p app/views/admin app/views/users app/policies

# ---- UserPolicy ----
cat > app/policies/user_policy.rb << 'RUBY'
class UserPolicy < ApplicationPolicy
  def index?   = user.admin?
  def show?    = user.admin? || record == user
  def edit?    = user.admin?
  def update?  = user.admin?
end
RUBY

# ---- AdminController (dashboard, audit log, batch QR) ----
cat > app/controllers/admin_controller.rb << 'RUBY'
class AdminController < ApplicationController
  before_action -> { authorize :admin, :access? }
  after_action :verify_authorized

  def dashboard
    @user_count = User.count
    @document_count = Document.count
    @pending_approvals = Approval.pending.count
    @active_assignments = Assignment.joins(:work_order).where(work_orders: { status: :in_progress }).count
  end

  def audit_log
    @versions = PaperTrail::Version.order(created_at: :desc).limit(50)
  end

  def batch_qr
  end
end
RUBY

# ---- AdminPolicy ----
cat > app/policies/admin_policy.rb << 'RUBY'
class AdminPolicy < Struct.new(:user, :admin)
  def access?  = user.admin?
  def dashboard? = access?
  def audit_log? = access?
  def batch_qr?  = access?
end
RUBY

# ---- UsersController ----
cat > app/controllers/users_controller.rb << 'RUBY'
class UsersController < ApplicationController
  before_action :set_user, only: %i[show edit update]
  after_action :verify_authorized

  def index
    @users = policy_scope(User).order(:name)
    authorize User
  end

  def show
  end

  def edit
  end

  def update
    if @user.update(user_params)
      redirect_to @user, notice: "User updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
    authorize @user
  end

  def user_params
    params.require(:user).permit(:name, :role, :department, :employee_id, :active)
  end
end
RUBY

# ---- Views ----

cat > app/views/users/index.html.erb << 'ERB'
<div class="flex items-center justify-between mb-6">
  <h1 class="text-2xl font-bold">Users</h1>
  <span class="badge badge-outline"><%= @users.count %> users</span>
</div>

<div class="overflow-x-auto">
  <table class="table table-zebra">
    <thead>
      <tr>
        <th>Name</th>
        <th>Email</th>
        <th>Role</th>
        <th>Department</th>
        <th>Employee ID</th>
        <th>Active</th>
        <th></th>
      </tr>
    </thead>
    <tbody>
      <% @users.each do |u| %>
        <tr>
          <td class="font-medium"><%= link_to u.name, u, class: "link link-hover" %></td>
          <td><%= u.email %></td>
          <td><%= role_badge(u.role) %></td>
          <td><%= u.department %></td>
          <td><%= u.employee_id %></td>
          <td><%= u.active ? "✓" : "✗" %></td>
          <td><%= link_to "Edit", edit_user_path(u), class: "btn btn-ghost btn-xs" %></td>
        </tr>
      <% end %>
    </tbody>
  </table>
</div>
ERB

cat > app/views/users/show.html.erb << 'ERB'
<div class="max-w-lg mx-auto">
  <div class="flex items-center justify-between mb-6">
    <h1 class="text-2xl font-bold"><%= @user.name %></h1>
    <% if policy(@user).edit? %>
      <%= link_to "Edit", edit_user_path(@user), class: "btn btn-outline btn-sm" %>
    <% end %>
  </div>

  <div class="card bg-base-200">
    <div class="card-body space-y-3">
      <div class="flex justify-between"><span class="text-base-content/60">Email</span><span><%= @user.email %></span></div>
      <div class="flex justify-between"><span class="text-base-content/60">Role</span><span><%= role_badge(@user.role) %></span></div>
      <div class="flex justify-between"><span class="text-base-content/60">Department</span><span><%= @user.department %></span></div>
      <div class="flex justify-between"><span class="text-base-content/60">Employee ID</span><span><%= @user.employee_id %></span></div>
      <div class="flex justify-between"><span class="text-base-content/60">Active</span><span><%= @user.active ? "Yes" : "No" %></span></div>
    </div>
  </div>
</div>
ERB

cat > app/views/users/edit.html.erb << 'ERB'
<div class="max-w-lg mx-auto">
  <h1 class="text-2xl font-bold mb-6">Edit User</h1>
  <%= form_with(model: @user, local: true, class: "space-y-4") do |f| %>
    <% if @user.errors.any? %>
      <div class="alert alert-error">
        <ul><% @user.errors.full_messages.each do |msg| %><li><%= msg %></li><% end %></ul>
      </div>
    <% end %>

    <div class="form-control">
      <%= f.label :name, class: "label" %>
      <%= f.text_field :name, class: "input input-bordered w-full" %>
    </div>

    <div class="form-control">
      <%= f.label :email, class: "label" %>
      <%= f.email_field :email, class: "input input-bordered w-full", disabled: true %>
    </div>

    <div class="form-control">
      <%= f.label :role, class: "label" %>
      <%= f.select :role, User.roles.keys.map { |r| [r.titleize, r] }, {}, class: "select select-bordered w-full" %>
    </div>

    <div class="form-control">
      <%= f.label :department, class: "label" %>
      <%= f.text_field :department, class: "input input-bordered w-full" %>
    </div>

    <div class="form-control">
      <%= f.label :employee_id, class: "label" %>
      <%= f.text_field :employee_id, class: "input input-bordered w-full" %>
    </div>

    <div class="form-control">
      <label class="label cursor-pointer justify-start gap-3">
        <%= f.check_box :active, class: "toggle toggle-primary" %>
        <span class="label-text">Active</span>
      </label>
    </div>

    <div class="flex items-center gap-3 pt-2">
      <%= f.submit class: "btn btn-primary" %>
      <%= link_to "Cancel", @user, class: "btn btn-ghost" %>
    </div>
  <% end %>
</div>
ERB

cat > app/views/admin/dashboard.html.erb << 'ERB'
<div class="mb-6">
  <h1 class="text-2xl font-bold">Admin Dashboard</h1>
</div>

<div class="stats stats-vertical lg:stats-horizontal shadow w-full mb-8">
  <div class="stat">
    <div class="stat-title">Users</div>
    <div class="stat-value"><%= @user_count %></div>
  </div>
  <div class="stat">
    <div class="stat-title">Documents</div>
    <div class="stat-value"><%= @document_count %></div>
  </div>
  <div class="stat">
    <div class="stat-title text-warning">Pending Approvals</div>
    <div class="stat-value text-warning"><%= @pending_approvals %></div>
  </div>
  <div class="stat">
    <div class="stat-title">Active Assignments</div>
    <div class="stat-value"><%= @active_assignments %></div>
  </div>
</div>

<div class="flex gap-3">
  <%= link_to "Manage Users", users_path, class: "btn btn-outline" %>
  <%= link_to "Audit Log", audit_log_path, class: "btn btn-outline" %>
  <%= link_to "Batch QR", batch_qr_path, class: "btn btn-outline" %>
</div>
ERB

cat > app/views/admin/audit_log.html.erb << 'ERB'
<div class="mb-6">
  <h1 class="text-2xl font-bold">Audit Log</h1>
  <p class="text-base-content/60 mt-1">Last 50 changes across all records</p>
</div>

<div class="overflow-x-auto">
  <table class="table table-zebra table-xs">
    <thead>
      <tr>
        <th>Time</th>
        <th>Type</th>
        <th>Event</th>
        <th>Item</th>
        <th>User</th>
      </tr>
    </thead>
    <tbody>
      <% @versions.each do |v| %>
        <tr>
          <td class="text-xs"><%= l v.created_at, format: :short %></td>
          <td><%= v.item_type %></td>
          <td><%= v.event.titleize %></td>
          <td><%= v.item_id %></td>
          <td class="text-xs"><%= User.find_by(id: v.whodunnit)&.name || "System" %></td>
        </tr>
      <% end %>
    </tbody>
  </table>
</div>
ERB

cat > app/views/admin/batch_qr.html.erb << 'ERB'
<div class="mb-6">
  <h1 class="text-2xl font-bold">Batch QR Code Generation</h1>
  <p class="text-base-content/60 mt-1">Coming soon.</p>
</div>
ERB

# ---- Helper additions ----
cat > app/helpers/application_helper.rb << 'RUBY'
module ApplicationHelper
  def status_badge(status)
    colors = {
      "draft" => "badge-ghost", "review" => "badge-warning",
      "approved" => "badge-success", "published" => "badge-info",
      "archived" => "badge-neutral"
    }
    content_tag :span, status.to_s.titleize, class: "badge #{colors[status.to_s] || 'badge-ghost'} badge-sm"
  end

  def approval_badge(decision)
    colors = {
      "pending" => "badge-ghost", "approved" => "badge-success",
      "rejected" => "badge-error", "changes_requested" => "badge-warning"
    }
    content_tag :span, decision.to_s.titleize, class: "badge #{colors[decision.to_s] || 'badge-ghost'} badge-sm"
  end

  def role_badge(role)
    colors = {
      "admin" => "badge-error", "approver" => "badge-warning",
      "reviewer" => "badge-info", "author" => "badge-primary",
      "scheduler" => "badge-success", "operator" => "badge-neutral",
      "viewer" => "badge-ghost"
    }
    content_tag :span, role.to_s.titleize, class: "badge #{colors[role.to_s] || 'badge-ghost'} badge-sm"
  end
end
RUBY

# ---- Additional routes for admin (inserted into routes.rb) ----
# Admin routes are already defined in the main routes file.

echo "=== Admin bootstrap complete ==="
