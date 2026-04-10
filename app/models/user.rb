class User < ApplicationRecord
  has_secure_password
  belongs_to :account
  has_many :sessions, dependent: :destroy
  has_many :expenses, dependent: :destroy
  has_many :meal_plans, dependent: :destroy
  has_many :lunch_logs, dependent: :destroy
  has_many :push_subscriptions, dependent: :destroy
  has_many :debt_payments, dependent: :destroy
  has_many :invitations, foreign_key: :invited_by_id, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  enum :role, { member: 0, owner: 1 }, default: :member

  scope :owner, -> { where(role: :owner) }

  validates :email_address, presence: true, uniqueness: true
end
