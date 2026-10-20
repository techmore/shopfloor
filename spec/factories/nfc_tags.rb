FactoryBot.define do
  factory :nfc_tag do
    sequence(:tag_uid) { |n| "04A2B3C4D5E#{n.to_s(16).rjust(3, '0').upcase}" }
    taggable { nil }
    written_by { nil }
    written_at { nil }
  end
end
