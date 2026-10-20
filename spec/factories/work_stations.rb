FactoryBot.define do
  factory :work_station do
    sequence(:name) { |n| "Station #{n}" }
    sequence(:code) { |n| "WS-#{n.to_s.rjust(2, '0')}" }
    station_type { :production }
    department { "Production" }
    description { "Main assembly line" }
  end
end
