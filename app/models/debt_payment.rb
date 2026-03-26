class DebtPayment < ApplicationRecord
  belongs_to :debt
  belongs_to :user

  validates :amount, numericality: { greater_than: 0 }
  validates :balance_after, numericality: { greater_than_or_equal_to: 0 }
  validates :paid_on, presence: true,
                      comparison: { less_than_or_equal_to: -> { Date.current },
                                    message: "cannot be a future date" }

  after_create :sync_debt_balance

  private

  def sync_debt_balance
    debt.update_columns(
      current_balance: balance_after,
      paid_off_at: balance_after.zero? ? Date.current : nil
    )
  end
end
