FactoryBot.define do
  factory :comment do
    commentable factory: :document
    author factory: :user
    body { "Please clarify section 3." }
    resolved_at { nil }
  end
end
