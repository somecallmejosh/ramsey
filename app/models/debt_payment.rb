class DebtPayment < ApplicationRecord
  belongs_to :debt
  belongs_to :user

  validates :amount, numericality: { greater_than: 0 }
  validates :balance_after, numericality: { greater_than_or_equal_to: 0 }
  validates :paid_on, presence: true,
                      comparison: { less_than_or_equal_to: -> { Date.current },
                                    message: "cannot be a future date" }

  validate :balance_after_not_above_prior_balance, on: :create

  scope :chronological, -> { order(:paid_on, :created_at, :id) }

  # Left blank, the new balance is the amount taken off the balance as of
  # the payment date. A statement balance, when entered, wins.
  before_validation :default_balance_after, on: :create
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

  # The debt's balance just before this payment.
  def prior_balance
    if latest?
      debt.current_balance
    else
      debt.debt_payments.where(paid_on: ..paid_on).chronological.last&.balance_after || debt.original_balance
    end
  end

  def default_balance_after
    return if balance_after.present? || paid_on.blank? || !amount.to_d.positive?

    self.balance_after = [ prior_balance - amount, 0 ].max
  end

  # A payment can only bring the balance down. A higher number is almost
  # always a typo (an extra digit), so catch it before it lands.
  def balance_after_not_above_prior_balance
    return if balance_after.blank? || paid_on.blank? || debt.nil?

    before = prior_balance
    return if balance_after <= before

    errors.add(:balance_after,
               "can't be more than the balance before this payment (#{ActiveSupport::NumberHelper.number_to_currency(before)}). Check for an extra digit.")
  end

  def capture_balance_before
    self.balance_before = prior_balance
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
