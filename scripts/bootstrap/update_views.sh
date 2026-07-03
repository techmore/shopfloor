#!/bin/bash
set -euo pipefail
source "$HOME/.asdf/asdf.sh"
cd /home/ubuntu/shopfloor

# HomeController
cat > app/controllers/home_controller.rb << 'HOME'
class HomeController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index]
  before_action :set_stats, only: [:dashboard]

  def index
    if user_signed_in?
      render :dashboard
    else
      render :landing
    end
  end

  def dashboard
  end

  def getting_started
  end

  private

  def set_stats
    @document_count   = Document.count
    @pending_reviews  = Document.where(status: "review").count
    @published_docs   = Document.where(status: "published").count
    @work_order_count = WorkOrder.count
    @shift_count      = Shift.count
    @part_count       = Part.count
    @weigh_count      = WeighSession.count
    @user_count       = User.count
  end
end
HOME

# DaisyUI CSS entry point
cat > app/assets/tailwind/application.css << 'CSS'
@import "tailwindcss";
@plugin "daisyui";
CSS

# Layout
cat > app/views/layouts/application.html.erb << 'LAYOUT'
<!DOCTYPE html>
<html data-theme="dark">
<head>
  <title>Shopfloor</title>
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <%= csrf_meta_tags %>
  <%= csp_meta_tag %>
  <%= stylesheet_link_tag "tailwind", "data-turbo-track": "reload" %>
  <%= javascript_importmap_tags %>
</head>
<body>
  <div class="drawer">
    <input id="nav-drawer" type="checkbox" class="drawer-toggle" />
    <div class="drawer-content flex flex-col">
      <div class="navbar bg-base-200 border-b border-base-300 sticky top-0 z-50">
        <div class="navbar-start">
          <label for="nav-drawer" class="btn btn-ghost lg:hidden">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"/></svg>
          </label>
          <%= link_to root_path, class: "btn btn-ghost text-xl gap-2" do %>
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.066 2.573c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.573 1.066c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.066-2.573c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/></svg>
            Shopfloor
          <% end %>
          <div class="hidden lg:flex items-center gap-1 ml-2">
            <% if user_signed_in? %>
              <%= link_to "Dashboard", root_path, class: "btn btn-ghost btn-sm" %>
              <div class="dropdown dropdown-hover dropdown-bottom">
                <div tabindex="0" role="button" class="btn btn-ghost btn-sm gap-1">
                  Modules
                  <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/></svg>
                </div>
                <ul tabindex="0" class="dropdown-content menu bg-base-200 rounded-box border border-base-300 z-50 w-48 p-2 shadow-lg">
                  <li><%= link_to "Documents", documents_path %></li>
                  <li><%= link_to "Schedule", schedule_path %></li>
                  <li><%= link_to "Weigh Stations", weigh_stations_path %></li>
                  <li><%= link_to "Parts / Inventory", parts_path %></li>
                  <li><%= link_to "Warehouse", warehouse_browse_path %></li>
                  <li><%= link_to "Shifts", shifts_path %></li>
                  <li><%= link_to "Work Orders", work_orders_path %></li>
                  <li class="divider my-1"></li>
                  <li><%= link_to "Stock Locations", stock_locations_path %></li>
                  <li><%= link_to "Shipments", shipments_path %></li>
                  <li><%= link_to "Bill of Materials", bill_of_materials_path %></li>
                  <li><%= link_to "NFC Tags", nfc_tags_path %></li>
                </ul>
              </div>
              <%= link_to "Getting Started", getting_started_path, class: "btn btn-ghost btn-sm" %>
              <% if current_user.admin? %>
                <%= link_to "Admin", admin_path, class: "btn btn-ghost btn-sm text-warning" %>
              <% end %>
            <% end %>
          </div>
        </div>
        <div class="navbar-end gap-2">
          <% if user_signed_in? %>
            <% role_colors = {"admin" => "badge-error", "viewer" => "badge-ghost", "author" => "badge-info", "reviewer" => "badge-warning", "approver" => "badge-success", "scheduler" => "badge-secondary", "operator" => "badge-neutral"} %>
            <span class="hidden sm:flex items-center gap-2">
              <span class="badge <%= role_colors[current_user.role] || 'badge-ghost' %> badge-sm"><%= current_user.role.titleize %></span>
              <span class="text-sm text-base-content/70"><%= current_user.name %></span>
            </span>
            <%= button_to "Sign out", destroy_user_session_path, method: :delete, class: "btn btn-ghost btn-sm" %>
          <% else %>
            <%= link_to "Sign in", new_user_session_path, class: "btn btn-primary btn-sm" %>
          <% end %>
        </div>
      </div>
      <main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 w-full">
        <% if notice %>
          <div class="alert alert-success mb-6">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
            <span><%= notice %></span>
          </div>
        <% end %>
        <% if alert %>
          <div class="alert alert-error mb-6">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
            <span><%= alert %></span>
          </div>
        <% end %>
        <%= yield %>
      </main>
    </div>
    <div class="drawer-side z-50">
      <label for="nav-drawer" aria-label="close sidebar" class="drawer-overlay"></label>
      <ul class="menu bg-base-200 min-h-full w-72 p-4 gap-1">
        <li class="menu-title text-lg gap-2 mb-2">
          <span>Shopfloor</span>
        </li>
        <% if user_signed_in? %>
          <li><%= link_to "Dashboard", root_path, class: "gap-2" %></li>
          <li class="menu-title text-xs mt-2">Modules</li>
          <li><%= link_to "Documents", documents_path, class: "gap-2" %></li>
          <li><%= link_to "Schedule", schedule_path, class: "gap-2" %></li>
          <li><%= link_to "Shifts", shifts_path, class: "gap-2" %></li>
          <li><%= link_to "Work Orders", work_orders_path, class: "gap-2" %></li>
          <li><%= link_to "Weigh Stations", weigh_stations_path, class: "gap-2" %></li>
          <li><%= link_to "Parts / Inventory", parts_path, class: "gap-2" %></li>
          <li><%= link_to "Stock Locations", stock_locations_path, class: "gap-2" %></li>
          <li><%= link_to "Bills of Materials", bill_of_materials_path, class: "gap-2" %></li>
          <li><%= link_to "Shipments", shipments_path, class: "gap-2" %></li>
          <li><%= link_to "Warehouse", warehouse_browse_path, class: "gap-2" %></li>
          <li><%= link_to "NFC Tags", nfc_tags_path, class: "gap-2" %></li>
          <li class="divider"></li>
          <li><%= link_to "Getting Started", getting_started_path, class: "gap-2" %></li>
          <% if current_user.admin? %>
            <li><%= link_to "Admin", admin_path, class: "gap-2 text-warning" %></li>
          <% end %>
        <% else %>
          <li><%= link_to "Sign in", new_user_session_path, class: "gap-2" %></li>
        <% end %>
      </ul>
    </div>
  </div>
</body>
</html>
LAYOUT

# Landing page
cat > app/views/home/landing.html.erb << 'LANDING'
<div class="hero min-h-[calc(100vh-8rem)]">
  <div class="hero-content text-center">
    <div class="max-w-3xl">
      <div class="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-primary/10 mb-6">
        <svg class="w-8 h-8 text-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.066 2.573c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.573 1.066c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.066-2.573c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/></svg>
      </div>
      <h1 class="text-5xl sm:text-6xl font-bold">Shopfloor</h1>
      <p class="text-xl text-base-content/70 mt-4">Manufacturing Operations Platform</p>
      <p class="text-base text-base-content/50 mt-2">ISO 9001 compliance &bull; Production scheduling &bull; Weigh stations &bull; Inventory management</p>
      <div class="mt-8 flex items-center justify-center gap-4">
        <%= link_to "Sign in", new_user_session_path, class: "btn btn-primary btn-lg" %>
      </div>
      <div class="mt-12 card bg-base-200/50 border border-base-300/50 text-left max-w-xl mx-auto">
        <div class="card-body">
          <h3 class="card-title text-sm">Demo Accounts</h3>
          <p class="text-xs text-base-content/50 mb-3">All accounts use password: <code class="text-accent">password123</code></p>
          <div class="overflow-x-auto">
            <table class="table table-xs">
              <thead>
                <tr><th>Email</th><th>Role</th><th>Department</th></tr>
              </thead>
              <tbody>
                <tr class="hover"><td><code>admin@shopfloor.local</code></td><td><span class="badge badge-error badge-xs">Admin</span></td><td>Management</td></tr>
                <tr class="hover"><td><code>scheduler@shopfloor.local</code></td><td><span class="badge badge-secondary badge-xs">Scheduler</span></td><td>Production</td></tr>
                <tr class="hover"><td><code>operator@shopfloor.local</code></td><td><span class="badge badge-neutral badge-xs">Operator</span></td><td>Production</td></tr>
                <tr class="hover"><td><code>author@shopfloor.local</code></td><td><span class="badge badge-info badge-xs">Author</span></td><td>Engineering</td></tr>
                <tr class="hover"><td><code>reviewer@shopfloor.local</code></td><td><span class="badge badge-warning badge-xs">Reviewer</span></td><td>Quality</td></tr>
                <tr class="hover"><td><code>approver@shopfloor.local</code></td><td><span class="badge badge-success badge-xs">Approver</span></td><td>Management</td></tr>
                <tr class="hover"><td><code>viewer@shopfloor.local</code></td><td><span class="badge badge-ghost badge-xs">Viewer</span></td><td>Quality</td></tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
      <div class="mt-10 grid grid-cols-1 sm:grid-cols-3 gap-4 max-w-3xl mx-auto">
        <div class="card bg-base-200/50 border border-base-300/50">
          <div class="card-body items-center text-center">
            <svg class="w-8 h-8 text-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
            <h3 class="card-title text-sm">ISO Documents</h3>
            <p class="text-xs text-base-content/60">Author, review, and approve quality documents with full audit trail</p>
          </div>
        </div>
        <div class="card bg-base-200/50 border border-base-300/50">
          <div class="card-body items-center text-center">
            <svg class="w-8 h-8 text-success" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/></svg>
            <h3 class="card-title text-sm">Production Schedule</h3>
            <p class="text-xs text-base-content/60">Plan shifts, assign work orders, and track daily goals per station</p>
          </div>
        </div>
        <div class="card bg-base-200/50 border border-base-300/50">
          <div class="card-body items-center text-center">
            <svg class="w-8 h-8 text-warning" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M3 6l3 1m0 0l-3 9a5.002 5.002 0 006.001 0M6 7l3 9M6 7l6-2m6 2l3-1m-3 1l-3 9a5.002 5.002 0 006.001 0M18 7l3 9m-3-9l-6-2m0-2v2m0 16V5m0 16H9m3 0h3"/></svg>
            <h3 class="card-title text-sm">Weigh &amp; Track</h3>
            <p class="text-xs text-base-content/60">Record weigh sessions with scale data, photos, labels, and NFC tags</p>
          </div>
        </div>
      </div>
      <div class="mt-4 grid grid-cols-1 sm:grid-cols-2 gap-4 max-w-[24rem] mx-auto">
        <div class="card bg-base-200/50 border border-base-300/50">
          <div class="card-body items-center text-center">
            <svg class="w-8 h-8 text-info" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"/></svg>
            <h3 class="card-title text-sm">Inventory &amp; BOM</h3>
            <p class="text-xs text-base-content/60">Track parts, stock locations, bills of materials, and shipments</p>
          </div>
        </div>
        <div class="card bg-base-200/50 border border-base-300/50">
          <div class="card-body items-center text-center">
            <svg class="w-8 h-8 text-secondary" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"/></svg>
            <h3 class="card-title text-sm">Team &amp; Roles</h3>
            <p class="text-xs text-base-content/60">Role-based access control for operators, authors, reviewers, and admins</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>
LANDING

# Dashboard
cat > app/views/home/dashboard.html.erb << 'DASH'
<div class="space-y-8">
  <div class="flex items-center justify-between">
    <div>
      <h1 class="text-2xl font-bold">Dashboard</h1>
      <p class="text-base-content/70 mt-1">Welcome back, <span class="font-medium"><%= current_user.name %></span>.</p>
    </div>
    <%= link_to getting_started_path, class: "btn btn-outline btn-sm gap-2" do %>
      <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
      Getting Started Guide
    <% end %>
  </div>

  <% if @document_count == 0 && @part_count == 0 %>
    <div class="alert alert-info">
      <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
      <div>
        <span class="font-bold">Welcome to Shopfloor!</span>
        <span class="ml-2">Your system is ready. Visit the <a href="<%= getting_started_path %>" class="underline">Getting Started Guide</a> to learn how to set up documents, parts, and production.</span>
      </div>
    </div>
  <% end %>

  <div class="stats stats-vertical lg:stats-horizontal shadow w-full">
    <div class="stat">
      <div class="stat-title">Documents</div>
      <div class="stat-value text-primary"><%= @document_count %></div>
      <div class="stat-desc"><%= @published_docs %> published &middot; <%= @pending_reviews %> pending review</div>
    </div>
    <div class="stat">
      <div class="stat-title">Work Orders</div>
      <div class="stat-value text-success"><%= @work_order_count %></div>
      <div class="stat-desc"><%= @shift_count %> shifts scheduled</div>
    </div>
    <div class="stat">
      <div class="stat-title">Parts</div>
      <div class="stat-value text-info"><%= @part_count %></div>
      <div class="stat-desc">in inventory catalog</div>
    </div>
    <div class="stat">
      <div class="stat-title">Weigh Sessions</div>
      <div class="stat-value text-warning"><%= @weigh_count %></div>
      <div class="stat-desc"><%= @user_count %> registered users</div>
    </div>
  </div>

  <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
    <div class="card bg-base-200/50 border border-base-300/50">
      <div class="card-body">
        <h2 class="card-title text-lg gap-2">
          <svg class="w-5 h-5 text-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
          ISO 9001 Document Control
        </h2>
        <p class="text-sm text-base-content/70">Manage quality documents with a full review workflow: draft &rarr; review &rarr; approve &rarr; publish &rarr; archive.</p>
        <div class="flex flex-wrap gap-2 mt-3">
          <% if policy(Document).create? %>
            <%= link_to "New Document", new_document_path, class: "btn btn-primary btn-sm" %>
          <% end %>
          <%= link_to "Browse Documents", documents_path, class: "btn btn-outline btn-sm" %>
        </div>
      </div>
    </div>

    <div class="card bg-base-200/50 border border-base-300/50">
      <div class="card-body">
        <h2 class="card-title text-lg gap-2">
          <svg class="w-5 h-5 text-success" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/></svg>
          Production Scheduling
        </h2>
        <p class="text-sm text-base-content/70">Define work stations, schedule shifts, create work orders, and assign tasks to operators.</p>
        <div class="flex flex-wrap gap-2 mt-3">
          <%= link_to "View Schedule", schedule_path, class: "btn btn-outline btn-sm" %>
          <% if current_user.admin? || current_user.scheduler? %>
            <%= link_to "New Shift", new_shift_path, class: "btn btn-outline btn-sm" %>
          <% end %>
        </div>
      </div>
    </div>

    <div class="card bg-base-200/50 border border-base-300/50">
      <div class="card-body">
        <h2 class="card-title text-lg gap-2">
          <svg class="w-5 h-5 text-warning" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 6l3 1m0 0l-3 9a5.002 5.002 0 006.001 0M6 7l3 9M6 7l6-2m6 2l3-1m-3 1l-3 9a5.002 5.002 0 006.001 0M18 7l3 9m-3-9l-6-2m0-2v2m0 16V5m0 16H9m3 0h3"/></svg>
          Weigh Stations
        </h2>
        <p class="text-sm text-base-content/70">Record weigh sessions at each station, generate labels, and track material flow over time.</p>
        <div class="flex flex-wrap gap-2 mt-3">
          <%= link_to "Weigh Stations", weigh_stations_path, class: "btn btn-outline btn-sm" %>
          <%= link_to "All Sessions", weigh_sessions_path, class: "btn btn-outline btn-sm" %>
        </div>
      </div>
    </div>

    <div class="card bg-base-200/50 border border-base-300/50">
      <div class="card-body">
        <h2 class="card-title text-lg gap-2">
          <svg class="w-5 h-5 text-info" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"/></svg>
          Inventory &amp; Parts
        </h2>
        <p class="text-sm text-base-content/70">Manage your parts catalog, stock locations, bills of materials, incoming/outgoing shipments, and NFC-tagged items.</p>
        <div class="flex flex-wrap gap-2 mt-3">
          <% if policy(Part).create? %>
            <%= link_to "New Part", new_part_path, class: "btn btn-primary btn-sm" %>
          <% end %>
          <%= link_to "Parts Catalog", parts_path, class: "btn btn-outline btn-sm" %>
          <%= link_to "Stock Locations", stock_locations_path, class: "btn btn-outline btn-sm" %>
        </div>
      </div>
    </div>
  </div>
</div>
DASH

# Getting Started guide
cat > app/views/home/getting_started.html.erb << 'GUIDE'
<div class="space-y-8">
  <div>
    <h1 class="text-2xl font-bold">Getting Started</h1>
    <p class="text-base-content/70 mt-1">A step-by-step guide to setting up your Shopfloor operations platform.</p>
  </div>

  <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
    <div class="card bg-base-200/50 border border-base-300/50">
      <div class="card-body">
        <div class="flex items-center gap-3 mb-3">
          <div class="flex items-center justify-center w-8 h-8 rounded-full bg-primary text-primary-content text-sm font-bold">1</div>
          <h2 class="card-title">Browse Demo Accounts</h2>
        </div>
        <p class="text-sm text-base-content/70">Sign in with different roles to understand the permission model. Each role sees different features and actions.</p>
        <div class="overflow-x-auto mt-3">
          <table class="table table-xs">
            <thead>
              <tr><th>Role</th><th>Can Do</th></tr>
            </thead>
            <tbody>
              <tr><td><span class="badge badge-error badge-xs">Admin</span></td><td>Everything — full system access</td></tr>
              <tr><td><span class="badge badge-info badge-xs">Author</span></td><td>Create and edit draft documents</td></tr>
              <tr><td><span class="badge badge-warning badge-xs">Reviewer</span></td><td>Review submitted documents</td></tr>
              <tr><td><span class="badge badge-success badge-xs">Approver</span></td><td>Approve/reject documents for publication</td></tr>
              <tr><td><span class="badge badge-secondary badge-xs">Scheduler</span></td><td>Manage shifts, work orders, assignments</td></tr>
              <tr><td><span class="badge badge-neutral badge-xs">Operator</span></td><td>Start/complete assignments, record weigh sessions</td></tr>
              <tr><td><span class="badge badge-ghost badge-xs">Viewer</span></td><td>Read-only access to documents and data</td></tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <div class="card bg-base-200/50 border border-base-300/50">
      <div class="card-body">
        <div class="flex items-center gap-3 mb-3">
          <div class="flex items-center justify-center w-8 h-8 rounded-full bg-primary text-primary-content text-sm font-bold">2</div>
          <h2 class="card-title">Set Up Work Stations</h2>
        </div>
        <p class="text-sm text-base-content/70">Define your production areas so you can schedule and track work per station.</p>
        <div class="mt-3">
          <p class="text-xs text-base-content/50 mb-2">Navigate to <strong>Schedule &rarr; Work Stations</strong> or click below:</p>
          <%= link_to "Manage Work Stations", work_stations_path, class: "btn btn-outline btn-sm" %>
        </div>
      </div>
    </div>

    <div class="card bg-base-200/50 border border-base-300/50">
      <div class="card-body">
        <div class="flex items-center gap-3 mb-3">
          <div class="flex items-center justify-center w-8 h-8 rounded-full bg-primary text-primary-content text-sm font-bold">3</div>
          <h2 class="card-title">Create Your First Document</h2>
        </div>
        <p class="text-sm text-base-content/70">Start your ISO 9001 compliance by creating a quality document. Follow the review workflow: draft &rarr; submit &rarr; review &rarr; approve &rarr; publish.</p>
        <p class="text-xs text-base-content/50 mt-2">Try it as <strong>Author</strong> or <strong>Admin</strong>.</p>
        <div class="mt-3 flex flex-wrap gap-2">
          <%= link_to "New Document", new_document_path, class: "btn btn-primary btn-sm" %>
          <%= link_to "All Documents", documents_path, class: "btn btn-outline btn-sm" %>
        </div>
      </div>
    </div>

    <div class="card bg-base-200/50 border border-base-300/50">
      <div class="card-body">
        <div class="flex items-center gap-3 mb-3">
          <div class="flex items-center justify-center w-8 h-8 rounded-full bg-primary text-primary-content text-sm font-bold">4</div>
          <h2 class="card-title">Add Parts &amp; Inventory</h2>
        </div>
        <p class="text-sm text-base-content/70">Build your parts catalog, define stock locations, and set up bills of materials for your products.</p>
        <p class="text-xs text-base-content/50 mt-2">Try it as <strong>Admin</strong>.</p>
        <div class="mt-3 flex flex-wrap gap-2">
          <%= link_to "New Part", new_part_path, class: "btn btn-primary btn-sm" %>
          <%= link_to "Parts Catalog", parts_path, class: "btn btn-outline btn-sm" %>
        </div>
      </div>
    </div>

    <div class="card bg-base-200/50 border border-base-300/50">
      <div class="card-body">
        <div class="flex items-center gap-3 mb-3">
          <div class="flex items-center justify-center w-8 h-8 rounded-full bg-primary text-primary-content text-sm font-bold">5</div>
          <h2 class="card-title">Schedule Production</h2>
        </div>
        <p class="text-sm text-base-content/70">Create shifts, assign workers to stations, define work orders, and track daily goals. Monitor progress on the schedule calendar.</p>
        <p class="text-xs text-base-content/50 mt-2">Try it as <strong>Scheduler</strong> or <strong>Admin</strong>.</p>
        <div class="mt-3 flex flex-wrap gap-2">
          <%= link_to "View Schedule", schedule_path, class: "btn btn-outline btn-sm" %>
          <%= link_to "New Shift", new_shift_path, class: "btn btn-outline btn-sm" %>
          <%= link_to "Work Orders", work_orders_path, class: "btn btn-outline btn-sm" %>
        </div>
      </div>
    </div>

    <div class="card bg-base-200/50 border border-base-300/50">
      <div class="card-body">
        <div class="flex items-center gap-3 mb-3">
          <div class="flex items-center justify-center w-8 h-8 rounded-full bg-primary text-primary-content text-sm font-bold">6</div>
          <h2 class="card-title">Record Weigh Sessions</h2>
        </div>
        <p class="text-sm text-base-content/70">At each weigh station, record sessions with weight data, photos, and optional NFC tag scanning. Generate labels for traceability.</p>
        <p class="text-xs text-base-content/50 mt-2">Try it as <strong>Operator</strong> or <strong>Admin</strong>.</p>
        <div class="mt-3 flex flex-wrap gap-2">
          <%= link_to "Weigh Stations", weigh_stations_path, class: "btn btn-outline btn-sm" %>
          <%= link_to "All Sessions", weigh_sessions_path, class: "btn btn-outline btn-sm" %>
        </div>
      </div>
    </div>
  </div>

  <div class="card bg-base-200 border border-base-300">
    <div class="card-body">
      <h2 class="card-title gap-2">
        <svg class="w-5 h-5 text-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"/></svg>
        ISO 9001 Compliance Overview
      </h2>
      <p class="text-sm text-base-content/70 mt-2">Shopfloor is designed to support ISO 9001:2015 quality management system requirements:</p>
      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 mt-4">
        <div class="bg-base-300/30 rounded-lg p-3">
          <h4 class="font-semibold text-sm">4.1 — Context</h4>
          <p class="text-xs text-base-content/60 mt-1">Define processes and work flows through work stations and work orders</p>
        </div>
        <div class="bg-base-300/30 rounded-lg p-3">
          <h4 class="font-semibold text-sm">7.5 — Documented Info</h4>
          <p class="text-xs text-base-content/60 mt-1">Full document lifecycle: draft, review, approve, publish, archive with version history</p>
        </div>
        <div class="bg-base-300/30 rounded-lg p-3">
          <h4 class="font-semibold text-sm">8.1 — Operational Planning</h4>
          <p class="text-xs text-base-content/60 mt-1">Production scheduling with shifts, assignments, and daily goals per work station</p>
        </div>
        <div class="bg-base-300/30 rounded-lg p-3">
          <h4 class="font-semibold text-sm">8.4 — Control of External Providers</h4>
          <p class="text-xs text-base-content/60 mt-1">Track incoming shipments and manage supplier parts with inventory tracking</p>
        </div>
        <div class="bg-base-300/30 rounded-lg p-3">
          <h4 class="font-semibold text-sm">8.5 — Production &amp; Service</h4>
          <p class="text-xs text-base-content/60 mt-1">Weigh sessions, part traceability via NFC tags, work order tracking</p>
        </div>
        <div class="bg-base-300/30 rounded-lg p-3">
          <h4 class="font-semibold text-sm">8.6 — Release of Products</h4>
          <p class="text-xs text-base-content/60 mt-1">Weigh station data capture, quality checks at each stage of production</p>
        </div>
        <div class="bg-base-300/30 rounded-lg p-3">
          <h4 class="font-semibold text-sm">9.1 — Monitoring &amp; Measurement</h4>
          <p class="text-xs text-base-content/60 mt-1">Audit log, PaperTrail versioning, dashboard stats, and assignment completion tracking</p>
        </div>
        <div class="bg-base-300/30 rounded-lg p-3">
          <h4 class="font-semibold text-sm">10.1 — Nonconformity &amp; Correction</h4>
          <p class="text-xs text-base-content/60 mt-1">Documented corrective actions through the document workflow and audit trail</p>
        </div>
        <div class="bg-base-300/30 rounded-lg p-3">
          <h4 class="font-semibold text-sm">10.3 — Continual Improvement</h4>
          <p class="text-xs text-base-content/60 mt-1">Review dashboards, approval workflows, and improvement tracking via quality documents</p>
        </div>
      </div>
    </div>
  </div>

  <div class="card bg-base-200 border border-base-300">
    <div class="card-body">
      <h2 class="card-title gap-2">
        <svg class="w-5 h-5 text-info" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6V4m0 2a2 2 0 100 4m0-4a2 2 0 110 4m-6 8a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4m6 6v10m6-2a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4"/></svg>
        Tips &amp; Next Steps
      </h2>
      <ul class="text-sm text-base-content/70 mt-3 space-y-2 list-disc list-inside">
        <li>Sign in as different users to see how permissions change what you can do.</li>
        <li>Create a <strong>Work Station</strong> first, then schedule a <strong>Shift</strong>, then create a <strong>Work Order</strong> and <strong>Assignment</strong> for a complete production flow.</li>
        <li>Add a <strong>Part</strong> and assign it to a <strong>Stock Location</strong> before creating a <strong>Bill of Materials</strong>.</li>
        <li>Use the <strong>Admin</strong> panel (<%= link_to "admin", admin_path, class: "underline" %>) to manage users, view the audit log, and generate batch QR codes.</li>
        <li>Each document goes through: Draft &rarr; Submit &rarr; Review &rarr; Approve &rarr; Publish &rarr; Archive. Try the full workflow!</li>
      </ul>
    </div>
  </div>
</div>
GUIDE

# Devise sign-in
mkdir -p app/views/devise/sessions
cat > app/views/devise/sessions/new.html.erb << 'SIGNIN'
<div class="min-h-[calc(100vh-10rem)] flex items-center justify-center">
  <div class="card bg-base-200 w-full max-w-md shrink-0">
    <div class="card-body">
      <div class="text-center mb-2">
        <div class="inline-flex items-center justify-center w-12 h-12 rounded-xl bg-primary/10 mb-3">
          <svg class="w-6 h-6 text-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.066 2.573c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.573 1.066c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.066-2.573c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/></svg>
        </div>
        <h1 class="text-xl font-bold">Sign in to Shopfloor</h1>
        <p class="text-base-content/60 text-sm mt-1">Manufacturing Operations Platform</p>
      </div>
      <%= form_for(resource, as: resource_name, url: session_path(resource_name)) do |f| %>
        <div class="form-control">
          <%= f.label :email, class: "label" %>
          <%= f.email_field :email, autofocus: true, autocomplete: "email", class: "input input-bordered", placeholder: "e.g. admin@shopfloor.local" %>
        </div>
        <div class="form-control mt-3">
          <%= f.label :password, class: "label" %>
          <%= f.password_field :password, autocomplete: "current-password", class: "input input-bordered", placeholder: "password123" %>
        </div>
        <% if devise_mapping.rememberable? %>
          <div class="form-control mt-3">
            <label class="label cursor-pointer justify-start gap-2">
              <%= f.check_box :remember_me, class: "checkbox checkbox-primary" %>
              <span class="label-text">Remember me</span>
            </label>
          </div>
        <% end %>
        <%= f.submit "Sign in", class: "btn btn-primary mt-4 w-full" %>
      <% end %>
      <div class="mt-4 p-3 bg-base-300/50 rounded-lg text-xs">
        <p class="font-medium mb-2">Demo Accounts — All use password: <code class="text-accent">password123</code></p>
        <div class="grid grid-cols-1 gap-1">
          <div><span class="badge badge-error badge-xs">Admin</span> <code>admin@shopfloor.local</code></div>
          <div><span class="badge badge-secondary badge-xs">Scheduler</span> <code>scheduler@shopfloor.local</code></div>
          <div><span class="badge badge-info badge-xs">Author</span> <code>author@shopfloor.local</code></div>
          <div><span class="badge badge-warning badge-xs">Reviewer</span> <code>reviewer@shopfloor.local</code></div>
          <div><span class="badge badge-success badge-xs">Approver</span> <code>approver@shopfloor.local</code></div>
          <div><span class="badge badge-neutral badge-xs">Operator</span> <code>operator@shopfloor.local</code></div>
          <div><span class="badge badge-ghost badge-xs">Viewer</span> <code>viewer@shopfloor.local</code></div>
        </div>
        <%= link_to "View full guide &rarr;".html_safe, getting_started_path, class: "block mt-2 text-center text-primary hover:underline" %>
      </div>
    </div>
  </div>
</div>
SIGNIN

echo "=== Views written ==="
