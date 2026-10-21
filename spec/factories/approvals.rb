FactoryBot.define do
  factory :approval do
    document
    approver factory: %i[user approver]
    decision { :pending }
    comment { "Looks good" }
    document_version { 1 }
    signed_at { nil }
  end
end
