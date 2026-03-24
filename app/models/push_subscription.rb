class PushSubscription < ApplicationRecord
  belongs_to :user
  validates :endpoint, :auth, :p256dh, presence: true
  validates :endpoint, uniqueness: true
end
