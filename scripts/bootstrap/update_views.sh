#!/bin/bash
set -euo pipefail
source "$HOME/.asdf/asdf.sh"
cd /home/ubuntu/shopfloor

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
  <div class="navbar bg-base-200 border-b border-base-300 sticky top-0 z-50">
    <div class="navbar-start">
      <%= link_to root_path, class: "btn btn-ghost text-xl gap-2" do %>
        <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.066 2.573c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.573 1.066c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.066-2.573c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/></svg>
        Shopfloor
      <% end %>
      <% if user_signed_in? %>
        <%= link_to "Docs", documents_path, class: "btn btn-ghost btn-sm" %>
        <%= link_to "Schedule", schedule_path, class: "btn btn-ghost btn-sm" %>
        <%= link_to "Weigh", weigh_stations_path, class: "btn btn-ghost btn-sm" %>
        <%= link_to "Inventory", parts_path, class: "btn btn-ghost btn-sm" %>
        <%= link_to "Warehouse", warehouse_browse_path, class: "btn btn-ghost btn-sm" %>
      <% end %>
    </div>
    <div class="navbar-end">
      <% if user_signed_in? %>
        <div class="flex items-center gap-2">
          <span class="badge badge-outline badge-sm gap-1">
            <span class="w-1.5 h-1.5 rounded-full bg-success"></span>
            <%= current_user.name %>
          </span>
          <%= button_to "Sign out", destroy_user_session_path, method: :delete, class: "btn btn-ghost btn-sm" %>
        </div>
      <% end %>
    </div>
  </div>
  <main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
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
</body>
</html>
LAYOUT

# Landing
cat > app/views/home/landing.html.erb << 'LANDING'
<div class="hero min-h-[calc(100vh-8rem)]">
  <div class="hero-content text-center">
    <div class="max-w-2xl">
      <div class="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-primary/10 mb-6">
        <svg class="w-8 h-8 text-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.066 2.573c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.573 1.066c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.066-2.573c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/></svg>
      </div>
      <h1 class="text-5xl sm:text-6xl font-bold">Shopfloor</h1>
      <p class="text-xl text-base-content/70 mt-4 max-w-lg mx-auto">Manufacturing Operations Platform</p>
      <p class="text-sm text-base-content/50 mt-2 max-w-md mx-auto">ISO compliance, production scheduling, weigh stations, and inventory management.</p>
      <div class="mt-8 flex items-center justify-center gap-4">
        <%= link_to "Sign in", new_user_session_path, class: "btn btn-primary btn-lg" %>
      </div>
      <div class="mt-16 grid grid-cols-1 sm:grid-cols-3 gap-4 max-w-3xl mx-auto">
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
    </div>
  </div>
</div>
LANDING

# Dashboard
cat > app/views/home/dashboard.html.erb << 'DASH'
<div class="space-y-8">
  <div>
    <h1 class="text-2xl font-bold">Dashboard</h1>
    <p class="text-base-content/70 mt-1">Welcome back, <span class="font-medium"><%= current_user.name %></span>.</p>
  </div>
  <div class="stats stats-vertical lg:stats-horizontal shadow w-full">
    <div class="stat">
      <div class="stat-title">Today&rsquo;s Schedule</div>
      <div class="stat-value text-primary">&mdash;</div>
      <div class="stat-desc">No shifts today</div>
    </div>
    <div class="stat">
      <div class="stat-title">Daily Goals</div>
      <div class="stat-value text-success">0%</div>
      <div class="stat-desc">0 of 0 units</div>
    </div>
    <div class="stat">
      <div class="stat-title">Pending Reviews</div>
      <div class="stat-value text-warning">0</div>
      <div class="stat-desc">No pending items</div>
    </div>
    <div class="stat">
      <div class="stat-title">Active Assignments</div>
      <div class="stat-value text-error">0</div>
      <div class="stat-desc">No active work</div>
    </div>
  </div>
</div>
DASH

# Devise sign-in
mkdir -p app/views/devise/sessions
cat > app/views/devise/sessions/new.html.erb << 'SIGNIN'
<div class="min-h-[calc(100vh-10rem)] flex items-center justify-center">
  <div class="card bg-base-200 w-full max-w-sm shrink-0">
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
          <%= f.email_field :email, autofocus: true, autocomplete: "email", class: "input input-bordered", placeholder: "email" %>
        </div>
        <div class="form-control mt-3">
          <%= f.label :password, class: "label" %>
          <%= f.password_field :password, autocomplete: "current-password", class: "input input-bordered", placeholder: "password" %>
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
      <div class="mt-4 text-center text-xs text-base-content/40">
        <p>Demo: admin@shopfloor.local / password123</p>
      </div>
    </div>
  </div>
</div>
SIGNIN

echo "=== Views written ==="
