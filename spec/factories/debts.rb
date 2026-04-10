FactoryBot.define do
  factory :debt do
    association :account
    sequence(:name) { |n| "Debt #{n}" }
    debt_type { :personal_loan }
    original_balance { 10_000 }
    current_balance  { 10_000 }
    minimum_payment  { 200 }
    interest_rate    { 22.0 }
    sequence(:position) { |n| n }
    paid_off_at { nil }

    trait :vehicle_loan do
      debt_type        { :vehicle_loan }
      original_balance { 15_000 }
      current_balance  { 15_000 }
      minimum_payment  { 300 }
      interest_rate    { 6.25 }
    end

    trait :mortgage do
      debt_type        { :mortgage }
      original_balance { 490_000 }
      current_balance  { 490_000 }
      minimum_payment  { 2_800 }
      interest_rate    { 6.125 }
    end

    trait :paid_off do
      current_balance { 0 }
      paid_off_at     { Date.current }
    end
  end
end
