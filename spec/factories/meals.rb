FactoryBot.define do
  factory :meal do
    association :meal_plan
    sequence(:day_of_week) { |n| n % 7 }
    dinner         { "Roast Chicken" }
    lunch          { "Chicken Salad" }
    prep_note      { nil }
    estimated_cost { 12.00 }
  end
end
