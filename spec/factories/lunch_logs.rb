FactoryBot.define do
  factory :lunch_log do
    association :user
    sequence(:logged_on) { |n| Date.new(2026, 3, 1) + (n - 1).days }
  end
end
