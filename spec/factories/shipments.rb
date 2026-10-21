FactoryBot.define do
  factory :shipment do
    sequence(:shipment_number) { |n| "SHP-#{n.to_s.rjust(5, '0')}" }
    nfc_tag { nil }
    contents { "12 x PN-00001" }
    gross_weight { 25.5 }
    net_weight { 24.0 }
    destination { "Customer A" }
    status { :created }
  end
end
