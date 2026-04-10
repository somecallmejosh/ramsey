FactoryBot.define do
  factory :invitation do
    association :account
    association :invited_by, factory: :user
    email { "invited@example.com" }
    expires_at { 7.days.from_now }
  end
end
