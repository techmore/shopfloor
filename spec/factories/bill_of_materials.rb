FactoryBot.define do
  factory :bill_of_material do
    parent_part_id { 1 }
    component_part_id { 1 }
    quantity_per_assembly { "9.99" }
    notes { "MyText" }
  end
end
