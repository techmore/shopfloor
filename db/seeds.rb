puts "Seeding..."
unless User.exists?(email: "admin@shopfloor.local")
  User.create!(email: "admin@shopfloor.local", password: "password123", password_confirmation: "password123", name: "Admin", role: :admin, department: "Management", employee_id: "ADMIN-001", active: true)
  puts "  Created admin: admin@shopfloor.local / password123"
end
[
  { email: "viewer@shopfloor.local",  name: "Viewer",   role: :viewer,   department: "Quality",   employee_id: "EMP-001" },
  { email: "operator@shopfloor.local", name: "Operator", role: :operator, department: "Production", employee_id: "EMP-002" },
  { email: "author@shopfloor.local",   name: "Author",   role: :author,   department: "Engineering", employee_id: "EMP-003" },
  { email: "reviewer@shopfloor.local", name: "Reviewer", role: :reviewer, department: "Quality",   employee_id: "EMP-004" },
  { email: "approver@shopfloor.local", name: "Approver", role: :approver, department: "Management", employee_id: "EMP-005" },
  { email: "scheduler@shopfloor.local",name: "Scheduler",role: :scheduler,department: "Production", employee_id: "EMP-006" },
].each do |u|
  unless User.exists?(email: u[:email])
    User.create!(**u, password: "password123", password_confirmation: "password123", active: true)
    puts "  Created #{u[:role]}: #{u[:email]} / password123"
  end
end
puts ""
puts "All passwords: password123"
