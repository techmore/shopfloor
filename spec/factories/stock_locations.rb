FactoryBot.define do
  factory :stock_location do
    name { "MyString" }
    code { "MyString" }
    aisle { "MyString" }
    rack { "MyString" }
    bin { "MyString" }
    pos_x { 1 }
    pos_y { 1 }
    parent_id { 1 }
    qr_code { "MyString" }
  end
end
