class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :expenses, dependent: :destroy
  has_many :meal_plans, dependent: :destroy
  has_many :lunch_logs, dependent: :destroy
  has_many :push_subscriptions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  enum :role, { standard: 0, admin: 1 }, default: :standard

  scope :admin, -> { where(role: :admin) }

  validates :email_address, presence: true, uniqueness: true
end
