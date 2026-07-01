FactoryBot.define do
  factory :notification do
    recipient_id { 1 }
    actor_id { 1 }
    action { "MyString" }
    notifiable { nil }
    read_at { "2026-06-30 22:21:40" }
  end
end
