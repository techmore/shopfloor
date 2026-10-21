FactoryBot.define do
  factory :notification do
    recipient factory: :user
    actor factory: :user
    notifiable factory: :document
    action { "document_submitted" }
    read_at { nil }
  end
end
