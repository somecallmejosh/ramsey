FactoryBot.define do
  factory :expense do
    association :envelope
    association :user
    amount { 25.00 }
    note { nil }
    transacted_on { Date.current }

    trait :prior_month do
      transacted_on { Date.current.last_month }
    end
  end
end
