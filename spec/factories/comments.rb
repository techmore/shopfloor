FactoryBot.define do
  factory :comment do
    body { "MyText" }
    author_id { 1 }
    commentable { nil }
    resolved_at { "2026-06-30 22:21:41" }
  end
end
