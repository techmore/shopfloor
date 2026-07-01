FactoryBot.define do
  factory :document do
    title { "MyString" }
    slug { "MyString" }
    status { 1 }
    author_id { 1 }
    category { nil }
    standard_ref { "MyString" }
    document_number { "MyString" }
    qr_code { "MyString" }
    version { 1 }
  end
end
