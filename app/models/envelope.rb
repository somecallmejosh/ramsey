class Envelope < ApplicationRecord
  has_many :envelope_budgets, dependent: :destroy
  has_many :expenses, dependent: :destroy

  validates :name, presence: true
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position) }

  def budget_for(year:, month:)
    envelope_budgets.find_by(year: year, month: month)&.amount || 0
  end

  def spent_in(year:, month:)
    expenses
      .where(transacted_on: Date.new(year, month).all_month)
      .sum(:amount)
  end
end
