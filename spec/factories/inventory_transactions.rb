FactoryBot.define do
  factory :inventory_transaction do
    part
    transaction_type { :receipt }
    quantity { 10 }
    reference { nil }
    user
    notes { nil }
  end
end
