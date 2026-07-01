FactoryBot.define do
  factory :shift do
    name { "MyString" }
    date { "2026-06-30" }
    start_time { "2026-06-30 22:21:33" }
    end_time { "2026-06-30 22:21:33" }
    work_station { nil }
  end
end
