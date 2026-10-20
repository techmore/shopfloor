FactoryBot.define do
  factory :weigh_session do
    work_order
    assignment { nil }
    part { work_order.part }
    worker factory: %i[user operator]
    weigh_station
    weight_value { 12.5 }
    unit { "kg" }
    nfc_tag { nil }
    printed_label { false }
    recorded_at { Time.current }
    synced_at { nil }
  end
end
