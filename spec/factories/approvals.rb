FactoryBot.define do
  factory :approval do
    approver_id { 1 }
    document_version { 1 }
    decision { 1 }
    comment { "MyText" }
    signed_at { "2026-06-30 22:21:42" }
  end
end
