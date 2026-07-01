FactoryBot.define do
  factory :work_order do
    order_number { "MyString" }
    part { nil }
    quantity { 1 }
    due_date { "2026-06-30" }
    status { 1 }
    priority { 1 }
    notes { "MyText" }
  end
end
