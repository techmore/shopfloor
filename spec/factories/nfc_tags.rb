FactoryBot.define do
  factory :nfc_tag do
    tag_uid { "MyString" }
    taggable { nil }
    written_at { "2026-06-30 22:21:38" }
    written_by_id { 1 }
  end
end
