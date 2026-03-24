FactoryBot.define do
  factory :push_subscription do
    association :user
    sequence(:endpoint) { |n| "https://fcm.googleapis.com/fcm/send/fake-endpoint-#{n}" }
    auth   { "fake-auth-key" }
    p256dh { "fake-p256dh-key" }
  end
end
