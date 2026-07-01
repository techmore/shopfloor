FactoryBot.define do
  factory :assignment do
    shift { nil }
    work_order { nil }
    worker_id { 1 }
    work_station { nil }
    planned_start { "2026-06-30 22:21:44" }
    planned_end { "2026-06-30 22:21:44" }
    actual_start { "2026-06-30 22:21:44" }
    actual_end { "2026-06-30 22:21:44" }
    notes { "MyText" }
  end
end
