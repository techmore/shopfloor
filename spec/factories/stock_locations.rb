FactoryBot.define do
  factory :stock_location do
    sequence(:name) { |n| "Location #{n}" }
    sequence(:code) { |n| "LOC-#{n.to_s.rjust(3, '0')}" }
    aisle { "A" }
    rack { "1" }
    bin { "B" }
    parent { nil }
    pos_x { 0 }
    pos_y { 0 }
    qr_code { nil }
  end
end
