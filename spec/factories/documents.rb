FactoryBot.define do
  factory :document do
    sequence(:title) { |n| "Quality Procedure #{n}" }
    sequence(:slug) { |n| "quality-procedure-#{n}" }
    sequence(:document_number) { |n| "QP-#{n.to_s.rjust(4, '0')}" }
    status { :draft }
    author factory: %i[user author]
    category
    standard_ref { "ISO 9001:2015 7.5" }
    qr_code { nil }
    version { 1 }
  end
end
