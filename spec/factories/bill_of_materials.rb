FactoryBot.define do
  factory :bill_of_material do
    parent_part factory: :part
    component_part factory: :part
    quantity_per_assembly { 2 }
    notes { nil }
  end
end
