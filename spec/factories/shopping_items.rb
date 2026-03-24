FactoryBot.define do
  factory :shopping_item do
    association :meal_plan
    name           { "Ground beef" }
    quantity       { "2 lbs" }
    estimated_cost { 8.00 }
    checked        { false }
    store          { "Aldi" }
  end
end
