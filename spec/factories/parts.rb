FactoryBot.define do
  factory :part do
    part_number { "MyString" }
    name { "MyString" }
    description { "MyText" }
    unit { "MyString" }
    category { "MyString" }
    reorder_point { 1 }
    lead_time_days { 1 }
    current_stock { 1 }
    stock_location { nil }
    qr_code { "MyString" }
  end
end
