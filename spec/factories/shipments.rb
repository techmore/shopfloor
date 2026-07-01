FactoryBot.define do
  factory :shipment do
    shipment_number { "MyString" }
    nfc_tag { nil }
    contents { "MyText" }
    gross_weight { "9.99" }
    net_weight { "9.99" }
    destination { "MyString" }
    status { 1 }
  end
end
