#!/bin/bash
# =============================================================================
# auth.sh — Devise + Pundit + Role enum on User
# =============================================================================
set -euo pipefail

APP_DIR="$HOME/$APP_NAME"
cd "$APP_DIR"

echo "=== Installing Devise ==="
rails generate devise:install

echo "=== Generate Devise User model ==="
rails generate devise User \
  role:integer \
  name:string \
  department:string \
  employee_id:string

echo "=== Run Devise migration ==="
rails db:migrate

echo "=== Setting up Pundit ==="
mkdir -p app/policies
cat > app/policies/application_policy.rb << 'RUBY'
class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?    = false
  def show?     = false
  def create?   = false
  def new?      = create?
  def update?   = false
  def edit?     = update?
  def destroy?  = false

  class Scope
    attr_reader :user, :scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end
    def resolve = scope.all
  end
end
RUBY

echo "=== Adding role enum to User model ==="
cat > app/models/user.rb << 'RUBY'
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum :role, {
    viewer: 0,
    operator: 1,
    author: 2,
    reviewer: 3,
    approver: 4,
    scheduler: 5,
    admin: 6
  }

  validates :name, presence: true
  validates :role, presence: true

  scope :active, -> { where(active: true) }

  def admin?       = role == "admin"
  def scheduler?   = role == "scheduler"
  def approver?    = role == "approver"
  def reviewer?    = role == "reviewer"
  def author?      = role == "author"
  def operator?    = role == "operator"
  def viewer?      = role == "viewer"

  def role_at_least?(minimum_role)
    User.roles[role] >= User.roles[minimum_role.to_s]
  end
end
RUBY

echo "=== Adding active boolean to User migration ==="
rails generate migration AddActiveToUsers active:boolean
rails db:migrate

echo "=== Add Pundit include to ApplicationController ==="
cat > app/controllers/application_controller.rb << 'RUBY'
class ApplicationController < ActionController::Base
  include Pundit::Authorization

  before_action :authenticate_user!

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_back(fallback_location: root_path)
  end
end
RUBY

echo "=== Done ==="
