class Debt < ApplicationRecord
  belongs_to :account
  enum :debt_type, { personal_loan: 0, vehicle_loan: 1, mortgage: 2,
                     student_loan: 3, medical: 4, other: 5 }

  has_many :debt_payments, dependent: :destroy

  scope :ordered,  -> { order(:position, :id) }
  scope :active,   -> { where(paid_off_at: nil) }
  scope :paid_off, -> { where.not(paid_off_at: nil) }
  scope :snowball, -> { where.not(debt_type: :mortgage) }
  scope :mortgage, -> { where(debt_type: :mortgage) }

  validates :name, :debt_type, :position, presence: true
  validates :original_balance, :current_balance, :minimum_payment,
            presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :interest_rate, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  before_save :sync_paid_off_at, if: :will_save_change_to_current_balance?

  def paid_off? = paid_off_at.present?

  def progress_pct
    return 0 if original_balance.zero?
    [ (original_balance - current_balance) / original_balance * 100, 0 ].max.round(1)
  end

  # Swap this debt with its neighbour in the active snowball list.
  # direction: :up (pay sooner) or :down (pay later).
  def move!(direction)
    list = account.debts.snowball.active.ordered.to_a
    index = list.index(self)
    return if index.nil?

    target = direction.to_sym == :up ? index - 1 : index + 1
    return if target.negative? || target >= list.size

    slots = list.map(&:position).sort
    slots = (slots.first...(slots.first + slots.size)).to_a if slots.uniq.size < slots.size

    list[index], list[target] = list[target], list[index]
    transaction do
      list.each_with_index do |debt, i|
        debt.update_column(:position, slots[i]) unless debt.position == slots[i]
      end
    end
  end

  private

  # A debt is paid off exactly when its balance reaches zero, whether that
  # happens through a logged payment or an edit.
  def sync_paid_off_at
    if current_balance&.zero?
      self.paid_off_at ||= Date.current
    else
      self.paid_off_at = nil
    end
  end
end
