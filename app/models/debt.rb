class Debt < ApplicationRecord
  belongs_to :account
  enum :debt_type, { personal_loan: 0, vehicle_loan: 1, mortgage: 2,
                     student_loan: 3, medical: 4, other: 5 }

  has_many :debt_payments, dependent: :destroy

  scope :ordered,  -> { order(:position) }
  scope :active,   -> { where(paid_off_at: nil) }
  scope :paid_off, -> { where.not(paid_off_at: nil) }
  scope :snowball, -> { where.not(debt_type: :mortgage) }
  scope :mortgage, -> { where(debt_type: :mortgage) }

  validates :name, :debt_type, :position, presence: true
  validates :original_balance, :current_balance, :minimum_payment,
            presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :interest_rate, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  def paid_off? = paid_off_at.present?

  def progress_pct
    return 0 if original_balance.zero?
    [(original_balance - current_balance) / original_balance * 100, 0].max.round(1)
  end
end
