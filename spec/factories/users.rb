FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@shopfloor.local" }
    sequence(:name) { |n| "User #{n}" }
    sequence(:employee_id) { |n| "EMP-#{n.to_s.rjust(3, '0')}" }
    password { "password123" }
    role { :viewer }
    department { "Production" }
    active { true }

    User.roles.each_key do |role_name|
      trait role_name.to_sym do
        role { role_name }
      end
    end

    trait :inactive do
      active { false }
    end
  end
end
