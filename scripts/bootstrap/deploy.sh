#!/bin/bash
# =============================================================================
# deploy.sh — Configure Capistrano + systemd service files for production
# =============================================================================
set -euo pipefail

APP_NAME="shopfloor"
APP_DIR="$HOME/$APP_NAME"
cd "$APP_DIR"

echo "=== Setting up Capistrano ==="
mkdir -p config/deploy

# Capfile
cat > Capfile << 'RUBY'
require "capistrano/setup"
require "capistrano/deploy"
require "capistrano/rails"
require "capistrano/bundler"
require "capistrano/rvm"

Dir.glob("lib/capistrano/tasks/*.rake").each { |r| import r }
RUBY

# config/deploy.rb
cat > config/deploy.rb << 'RUBY'
lock "~> 3.19"

set :application, "shopfloor"
set :repo_url,  ENV.fetch("REPO_URL", "git@github.com:your-org/shopfloor.git")
set :branch,    ENV.fetch("BRANCH", "main")

set :deploy_to, "/home/deploy/shopfloor"
set :keep_releases, 5

set :rvm_ruby_version, "3.4.1"

set :linked_files, %w[config/master.key config/database.yml config/secrets.yml]
set :linked_dirs,  %w[log tmp/pids tmp/cache tmp/sockets storage public/uploads]

set :puma_service_unit_name, "puma"
set :puma_systemctl_user, :system

set :conditionally_migrate, true

namespace :deploy do
  after :finishing, "deploy:restart_puma"
  after :finishing, "deploy:restart_solid_queue"
end
RUBY

# config/deploy/production.rb
cat > config/deploy/production.rb << 'RUBY'
server ENV.fetch("PRODUCTION_HOST", "10.0.0.50"),
       user: "deploy",
       roles: %w[app web db]

set :branch, "main"
set :rails_env, "production"
set :deploy_to, "/home/deploy/shopfloor"
RUBY

# config/deploy/staging.rb
cat > config/deploy/staging.rb << 'RUBY'
server ENV.fetch("STAGING_HOST", "10.0.0.51"),
       user: "deploy",
       roles: %w[app web db]

set :branch, "develop"
set :rails_env, "staging"
set :deploy_to, "/home/deploy/shopfloor-staging"
RUBY

echo "=== Creating systemd service files ==="
mkdir -p deploy

# Puma service
cat > deploy/puma.service << 'UNIT'
[Unit]
Description=Puma Rails Server (Shopfloor)
After=network.target postgresql.service redis.service

[Service]
Type=simple
User=deploy
WorkingDirectory=/home/deploy/shopfloor/current
ExecStart=/home/deploy/.asdf/shims/bundle exec puma -C config/puma.rb
ExecReload=/bin/kill -USR1 $MAINPID
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
UNIT

# Solid Queue worker service
cat > deploy/solid_queue.service << 'UNIT'
[Unit]
Description=Solid Queue Worker (Shopfloor)
After=network.target postgresql.service redis.service

[Service]
Type=simple
User=deploy
WorkingDirectory=/home/deploy/shopfloor/current
ExecStart=/home/deploy/.asdf/shims/bundle exec rails jobs:work
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
UNIT

echo "=== Configuring Puma for production ==="
cat > config/puma.rb << 'RUBY'
max_threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
threads min_threads_count, max_threads_count

worker_timeout 3600 if ENV.fetch("RAILS_ENV", "development") == "development"

port ENV.fetch("PORT") { 3000 }

environment ENV.fetch("RAILS_ENV") { "development" }

pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }

plugin :tmp_restart
RUBY

echo "=== Creating Procfile for foreman ==="
cat > Procfile << 'PROC'
web: bin/rails server -b 0.0.0.0 -p 3000
worker: bin/rails jobs:work
css: bin/rails tailwindcss:watch
PROC

echo "=== Creating .env.example ==="
cat > .env.example << 'ENV'
RAILS_ENV=development
DATABASE_URL=postgres://ubuntu:@localhost:5432/shopfloor_development
REDIS_URL=redis://localhost:6379/1
SECRET_KEY_BASE=change-me
ENV

echo "=== Adding Capistrano deploy task files ==="
mkdir -p lib/capistrano/tasks

cat > lib/capistrano/tasks/puma.rake << 'RUBY'
namespace :puma do
  desc "Restart Puma"
  task :restart do
    on roles(:app) do
      execute :sudo, :systemctl, :restart, "puma"
    end
  end
end
RUBY

cat > lib/capistrano/tasks/solid_queue.rake << 'RUBY'
namespace :solid_queue do
  desc "Restart Solid Queue"
  task :restart do
    on roles(:app) do
      execute :sudo, :systemctl, :restart, "solid_queue"
    end
  end
end
RUBY

echo "=== Done ==="
echo ""
echo "To deploy to production:"
echo "  1. Copy deploy/*.service to production: scp deploy/*.service root@host:/etc/systemd/system/"
echo "  2. On production: systemctl daemon-reload && systemctl enable --now puma solid_queue"
echo "  3. From dev: cap production deploy"
