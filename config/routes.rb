Rails.application.routes.draw do
  root "home#index"

  resources :documents do
    member do
      post :submit
      post :approve
      post :reject
      post :publish
      post :archive
    end
  end
  get "documents/:id/qr_code", to: "documents#qr_code", as: :document_qr
  get "documents/:id/versions", to: "documents#versions", as: :document_versions
  get "documents/:id/diff", to: "documents#diff", as: :document_diff

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

  devise_for :users

  resources :users, only: [:index, :show, :edit, :update]
  get "admin", to: "admin#dashboard"
  get "qr/batch", to: "admin#batch_qr"
  get "audit", to: "admin#audit_log"
  get "getting_started", to: "home#getting_started"

  get "up" => "rails/health#show", as: :rails_health_check
end
