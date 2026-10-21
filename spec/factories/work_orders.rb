FactoryBot.define do
  factory :work_order do
    sequence(:order_number) { |n| "WO-#{n.to_s.rjust(5, '0')}" }
    part
    quantity { 50 }
    due_date { Date.current + 7 }
    status { :planned }
    priority { :normal }
    notes { nil }
  end
end
