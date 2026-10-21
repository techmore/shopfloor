FactoryBot.define do
  factory :daily_goal do
    work_station
    worker factory: %i[user operator]
    date { Date.current }
    target_quantity { 100 }
    achieved_quantity { 0 }
    unit { "units" }
  end
end
