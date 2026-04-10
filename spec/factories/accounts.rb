FactoryBot.define do
  factory :account do
    sequence(:name) { |n| "Household #{n}" }
  end
end
