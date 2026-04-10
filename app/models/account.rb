class Account < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :envelopes, dependent: :destroy
  has_many :debts, dependent: :destroy
  has_many :meal_plans, dependent: :destroy
  has_many :invitations, dependent: :destroy

  has_many :expenses, through: :envelopes
  has_many :envelope_budgets, through: :envelopes
  has_many :debt_payments, through: :debts

  validates :name, presence: true
end
