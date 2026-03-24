FactoryBot.define do
  factory :meal_plan do
    association :user
    week_start { Date.current.beginning_of_week(:sunday) }
    confirmed_at { nil }

    trait :confirmed do
      confirmed_at { Time.current }
    end

    trait :prior_week do
      week_start { Date.current.beginning_of_week(:sunday) - 1.week }
    end
  end
end
