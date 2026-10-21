FactoryBot.define do
  factory :weigh_station do
    sequence(:name) { |n| "Weigh Station #{n}" }
    sequence(:code) { |n| "WGH-#{n.to_s.rjust(2, '0')}" }
    ip_address { "192.168.1.50" }
    has_scale { true }
    has_camera { false }
    has_printer { true }
    has_nfc_reader { false }
    scale_type { "serial" }
    printer_model { "Zebra ZD420" }
  end
end
