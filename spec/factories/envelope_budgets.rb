FactoryBot.define do
  factory :envelope_budget do
    association :envelope
    year { Date.current.year }
    month { Date.current.month }
    amount { 500.00 }

    trait :prior_month do
      year { Date.current.last_month.year }
      month { Date.current.last_month.month }
    end
  end
end
