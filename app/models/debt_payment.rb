class DebtPayment < ApplicationRecord
  belongs_to :debt
  belongs_to :user

  validates :amount, numericality: { greater_than: 0 }
  validates :balance_after, numericality: { greater_than_or_equal_to: 0 }
  validates :paid_on, presence: true,
                      comparison: { less_than_or_equal_to: -> { Date.current },
                                    message: "cannot be a future date" }

  scope :chronological, -> { order(:paid_on, :created_at, :id) }

  before_create :capture_balance_before
  after_create  :sync_debt_balance
  after_destroy :restore_debt_balance, unless: :destroyed_by_association

  # The debt's balance once this payment is removed. Only the most recent
  # payment sets the balance, so removing an older one changes nothing.
  def balance_if_removed
    return debt.current_balance unless latest?

    balance_before || latest_other_payment&.balance_after || debt.original_balance
  end

  # Sort key matching the chronological scope. Unsaved records sort last
  # among payments on the same day, since they will be created last.
  def chronology_key
    [ paid_on, created_at || Time.current, id || Float::INFINITY ]
  end

  private

  def latest?
    other = latest_other_payment
    other.nil? || (chronology_key <=> other.chronology_key).positive?
  end

  def latest_other_payment
    scope = debt.debt_payments.chronological
    scope = scope.where.not(id: id) if id
    scope.last
  end

  def capture_balance_before
    self.balance_before =
      if latest?
        debt.current_balance
      else
        debt.debt_payments.where(paid_on: ..paid_on).chronological.last&.balance_after
      end
  end

  def sync_debt_balance
    set_debt_balance(balance_after, paid_on) if latest?
  end

  def restore_debt_balance
    set_debt_balance(balance_if_removed, latest_other_payment&.paid_on)
  end

  def set_debt_balance(balance, paid_off_on)
    debt.update!(
      current_balance: balance,
      paid_off_at: balance.zero? ? (paid_off_on || Date.current) : nil
    )
  end
end
