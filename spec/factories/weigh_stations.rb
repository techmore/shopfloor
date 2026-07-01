FactoryBot.define do
  factory :weigh_station do
    name { "MyString" }
    code { "MyString" }
    has_scale { false }
    has_camera { false }
    has_printer { false }
    has_nfc_reader { false }
    ip_address { "MyString" }
    scale_type { "MyString" }
    printer_model { "MyString" }
  end
end
