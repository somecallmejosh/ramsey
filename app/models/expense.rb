class Expense < ApplicationRecord
  belongs_to :envelope
  belongs_to :user

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :transacted_on, presence: true,
                            comparison: { less_than_or_equal_to: -> { Date.current },
                                          message: "cannot be a future date" }

  scope :current_month, -> {
    where(transacted_on: Date.current.beginning_of_month..Date.current.end_of_month)
  }

  scope :prior_month, -> {
    where("transacted_on < ?", Date.current.beginning_of_month)
  }

  scope :for_month, ->(year, month) {
    where(transacted_on: Date.new(year, month).all_month)
  }

  def prior_month?
    transacted_on < Date.current.beginning_of_month
  end
end
