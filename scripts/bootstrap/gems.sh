#!/bin/bash
# =============================================================================
# gems.sh — Add all gem dependencies and bundle install
# =============================================================================
set -euo pipefail

APP_DIR="$HOME/$APP_NAME"

echo "=== Adding gems to Gemfile ==="

cd "$APP_DIR"

# --- Insert gem lines before the last group/end in Gemfile ---
# We do this by reading the Gemfile and writing a new one

# Core application gems
cat >> Gemfile << 'GEMS'

# =============================================================================
# Application Core
# =============================================================================
gem "devise"
gem "pundit"
gem "paper_trail"
gem "aasm"
gem "rqrcode"
gem "pg_search"
gem "simple_calendar"
gem "chartkick"
gem "groupdate"
gem "kaminari"
gem "view_component"

# =============================================================================
# Background Jobs
# =============================================================================
gem "solid_queue"

# =============================================================================
# Frontend
# =============================================================================
gem "tailwindcss-rails"

# =============================================================================
# Development & Test
# =============================================================================
group :development, :test do
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker"
  gem "pry-rails"
  gem "standard"
  gem "brakeman"
  gem "bundler-audit"
end

group :development do
  gem "capistrano", "~> 3.19"
  gem "capistrano-rails", "~> 1.7"
  gem "capistrano-bundler", "~> 2.1"
  gem "capistrano-rvm"
  gem "foreman"
  gem "annotate"
  gem "solargraph"
  gem "letter_opener"
end

group :test do
  gem "shoulda-matchers"
  gem "cuprite"
  gem "simplecov", require: false
end
GEMS

echo "=== Bundle install ==="
bundle install

echo "=== Done ==="
