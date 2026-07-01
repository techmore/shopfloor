FactoryBot.define do
  factory :inventory_transaction do
    part { nil }
    transaction_type { 1 }
    quantity { 1 }
    reference { nil }
    user_id { 1 }
    notes { "MyText" }
  end
end
