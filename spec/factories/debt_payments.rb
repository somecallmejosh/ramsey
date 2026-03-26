FactoryBot.define do
  factory :debt_payment do
    association :debt
    association :user
    amount        { 500 }
    balance_after { 9_500 }
    paid_on       { Date.current }
    note          { nil }
  end
end
