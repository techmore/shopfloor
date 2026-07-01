FactoryBot.define do
  factory :weigh_session do
    work_order { nil }
    assignment { nil }
    part { nil }
    worker_id { 1 }
    weigh_station { nil }
    weight_value { "9.99" }
    unit { "MyString" }
    nfc_tag { "MyString" }
    printed_label { false }
    recorded_at { "2026-06-30 22:21:45" }
    synced_at { "2026-06-30 22:21:45" }
  end
end
