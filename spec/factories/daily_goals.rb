FactoryBot.define do
  factory :daily_goal do
    date { "2026-06-30" }
    work_station { nil }
    worker_id { 1 }
    target_quantity { 1 }
    unit { "MyString" }
    achieved_quantity { 1 }
  end
end
