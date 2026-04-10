FactoryBot.define do
  factory :user do
    association :account
    sequence(:email_address) { |n| "user#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }
    role { :member }

    trait :owner do
      role { :owner }
    end

    # Backwards-compatible alias
    trait :admin do
      role { :owner }
    end
  end
end
