#!/bin/bash
# =============================================================================
# frontend.sh — Configure Tailwind, ViewComponent, layout
# =============================================================================
set -euo pipefail

APP_DIR="$HOME/$APP_NAME"
cd "$APP_DIR"

echo "=== Installing Tailwind ==="
rails tailwindcss:install

echo "=== Installing ViewComponent ==="
rails generate view_component:install

echo "=== Creating application layout with nav ==="
cat > app/views/layouts/application.html.erb << 'ERB'
<!DOCTYPE html>
<html>
<head>
  <title>Shopfloor</title>
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <%= csrf_meta_tags %>
  <%= csp_meta_tag %>
  <%= stylesheet_link_tag "tailwind", "data-turbo-track": "reload" %>
  <%= javascript_importmap_tags %>
</head>
<body class="bg-slate-900 text-slate-300 font-sans antialiased">

  <nav class="bg-slate-800 border-b border-slate-700 px-6 py-3">
    <div class="max-w-6xl mx-auto flex items-center justify-between">
      <div class="flex items-center gap-6">
        <%= link_to "Shopfloor", root_path, class: "text-white font-bold text-lg" %>
        <%= link_to "Docs", documents_path, class: "text-slate-400 hover:text-white text-sm" %>
        <%= link_to "Schedule", schedule_path, class: "text-slate-400 hover:text-white text-sm" %>
        <%= link_to "Weigh", weigh_stations_path, class: "text-slate-400 hover:text-white text-sm" %>
        <%= link_to "Inventory", parts_path, class: "text-slate-400 hover:text-white text-sm" %>
      </div>
      <div class="flex items-center gap-4 text-sm">
        <% if user_signed_in? %>
          <span class="text-slate-500"><%= current_user.name %></span>
          <%= link_to "Sign out", destroy_user_session_path, data: { turbo_method: :delete }, class: "text-slate-400 hover:text-white" %>
        <% else %>
          <%= link_to "Sign in", new_user_session_path, class: "text-indigo-400 hover:text-indigo-300" %>
        <% end %>
      </div>
    </div>
  </nav>

  <main class="max-w-6xl mx-auto px-6 py-8">
    <% if notice %><p class="text-emerald-400 text-sm mb-4"><%= notice %></p><% end %>
    <% if alert %><p class="text-red-400 text-sm mb-4"><%= alert %></p><% end %>
    <%= yield %>
  </main>

</body>
</html>
ERB

echo "=== Creating dashboard controller ==="
cat > app/controllers/home_controller.rb << 'RUBY'
class HomeController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index]

  def index
    if user_signed_in?
      render :dashboard
    else
      render :landing
    end
  end
end
RUBY

cat > app/views/home/landing.html.erb << 'ERB'
<div class="text-center py-20">
  <h1 class="text-5xl font-bold text-white">Shopfloor</h1>
  <p class="text-slate-400 mt-4 text-lg">Manufacturing Operations Platform</p>
  <div class="mt-8">
    <%= link_to "Sign in", new_user_session_path, class: "bg-indigo-600 text-white px-6 py-3 rounded-lg font-semibold hover:bg-indigo-500" %>
  </div>
</div>
ERB

cat > app/views/home/dashboard.html.erb << 'ERB'
<h1 class="text-2xl font-bold text-white">Dashboard</h1>
<p class="text-slate-400 mt-2">Welcome back, <%= current_user.name %>.</p>

<div class="mt-8 grid grid-cols-1 md:grid-cols-3 gap-6">
  <div class="bg-slate-800 rounded-xl p-5 border border-slate-700">
    <h2 class="text-indigo-400 font-semibold text-sm">Today's Schedule</h2>
    <p class="text-2xl font-bold text-white mt-2">—</p>
    <p class="text-slate-500 text-xs mt-1">Calendar view coming soon</p>
  </div>
  <div class="bg-slate-800 rounded-xl p-5 border border-slate-700">
    <h2 class="text-emerald-400 font-semibold text-sm">Daily Goals</h2>
    <p class="text-2xl font-bold text-white mt-2">0%</p>
    <p class="text-slate-500 text-xs mt-1">Goals set on schedule page</p>
  </div>
  <div class="bg-slate-800 rounded-xl p-5 border border-slate-700">
    <h2 class="text-amber-400 font-semibold text-sm">Pending Reviews</h2>
    <p class="text-2xl font-bold text-white mt-2">0</p>
    <p class="text-slate-500 text-xs mt-1">Documents awaiting approval</p>
  </div>
</div>
ERB

echo "=== Setting root route ==="
cat > config/routes.rb << 'RUBY'
Rails.application.routes.draw do
  root "home#index"

  # Documents
  resources :documents do
    member do
      post :submit
      post :approve
      post :reject
      post :publish
      post :archive
    end
    collection do
      get :search
    end
  end
  get "documents/:id/qr_code", to: "documents#qr_code", as: :document_qr
  get "documents/:id/versions", to: "documents#versions", as: :document_versions
  get "documents/:id/diff", to: "documents#diff", as: :document_diff

  # Schedule
  get "schedule", to: "schedule#index"
  get "schedule/my", to: "schedule#my"
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

  # Weigh Station
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
  post "nfc_tags/scan", to: "nfc_tags#scan"

  # Inventory
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
  get "warehouse/map", to: "warehouse#map"
  get "warehouse/browse", to: "warehouse#browse"

  # Admin
  resources :users, only: [:index, :edit, :update]
  get "qr/batch", to: "admin#batch_qr"
  get "audit", to: "admin#audit_log"

  # Devise
  devise_for :users
end
RUBY

echo "=== Generating controllers (scaffold stubs) ==="
# Generate empty controllers for each resource
for ctrl in documents schedule shifts work_orders assignments work_stations \
           daily_goals weigh_stations weigh_sessions shipments nfc_tags \
           parts stock_locations inventory_transactions bill_of_materials \
           categories warehouse users admin; do
  if [ ! -f "app/controllers/${ctrl}_controller.rb" ]; then
cat > "app/controllers/${ctrl}_controller.rb" << RUBY
class ${ctrl^}Controller < ApplicationController
  def index
    # TODO: implement
  end
end
RUBY
  fi
done

echo "=== Done ==="
