FactoryBot.define do
  factory :part do
    sequence(:part_number) { |n| "PN-#{n.to_s.rjust(5, '0')}" }
    sequence(:name) { |n| "Part #{n}" }
    description { "A widget" }
    unit { "ea" }
    category { "Hardware" }
    reorder_point { 10 }
    lead_time_days { 7 }
    current_stock { 100 }
    stock_location
    qr_code { nil }
  end
end
