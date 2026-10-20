FactoryBot.define do
  factory :shift do
    sequence(:name) { |n| "Shift #{n}" }
    work_station
    date { Date.current }
    start_time { "08:00" }
    end_time { "16:00" }
  end
end
