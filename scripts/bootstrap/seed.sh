#!/bin/bash
# =============================================================================
# seed.sh — Create database, seed roles, set up PaperTrail
# =============================================================================
set -euo pipefail

APP_DIR="$HOME/$APP_NAME"
cd "$APP_DIR"

echo "=== Creating database ==="
rails db:create 2>/dev/null || echo "Database already exists"
rails db:migrate

echo "=== Seeding roles and default admin ==="
cat > db/seeds.rb << 'RUBY'
puts "Seeding..."

# Create default admin user
unless User.exists?(email: "admin@shopfloor.local")
  User.create!(
    email: "admin@shopfloor.local",
    password: "password123",
    password_confirmation: "password123",
    name: "Admin",
    role: :admin,
    department: "Management",
    employee_id: "ADMIN-001",
    active: true
  )
  puts "  Created admin user: admin@shopfloor.local / password123"
end

# Create demo users for each role
demo_users = [
  { email: "viewer@shopfloor.local",  name: "Demo Viewer",    role: :viewer,    department: "Quality",   employee_id: "EMP-001" },
  { email: "operator@shopfloor.local", name: "Demo Operator",  role: :operator,  department: "Production", employee_id: "EMP-002" },
  { email: "author@shopfloor.local",   name: "Demo Author",    role: :author,    department: "Engineering", employee_id: "EMP-003" },
  { email: "reviewer@shopfloor.local", name: "Demo Reviewer",  role: :reviewer,  department: "Quality",   employee_id: "EMP-004" },
  { email: "approver@shopfloor.local", name: "Demo Approver",  role: :approver,  department: "Management", employee_id: "EMP-005" },
  { email: "scheduler@shopfloor.local",name: "Demo Scheduler", role: :scheduler, department: "Production", employee_id: "EMP-006" },
]

demo_users.each do |attrs|
  unless User.exists?(email: attrs[:email])
    User.create!(**attrs, password: "password123", password_confirmation: "password123", active: true)
    puts "  Created #{attrs[:role]} user: #{attrs[:email]} / password123"
  end
end

puts "Seeding complete!"
puts ""
puts "Login with any demo account:"
puts "  Email:    admin@shopfloor.local (or any demo user)"
puts "  Password: password123"
RUBY

rails db:seed

echo "=== Done ==="
