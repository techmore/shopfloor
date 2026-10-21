FactoryBot.define do
  factory :assignment do
    shift
    work_order
    work_station { shift.work_station }
    worker factory: %i[user operator]
    planned_start { Time.current.change(hour: 8) }
    planned_end { Time.current.change(hour: 16) }
    actual_start { nil }
    actual_end { nil }
    notes { nil }

    trait :started do
      actual_start { Time.current.change(hour: 8, min: 5) }
    end

    trait :completed do
      actual_start { Time.current.change(hour: 8, min: 5) }
      actual_end { Time.current.change(hour: 15, min: 50) }
    end
  end
end
