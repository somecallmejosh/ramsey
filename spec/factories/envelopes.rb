FactoryBot.define do
  factory :envelope do
    association :account
    sequence(:name) { |n| "Envelope #{n}" }
    sequence(:position) { |n| n }
    active { true }
  end
end
