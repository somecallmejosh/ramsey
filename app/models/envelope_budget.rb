class EnvelopeBudget < ApplicationRecord
  belongs_to :envelope

  validates :year, presence: true, numericality: { only_integer: true }
  validates :month, presence: true,
                    numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 12 },
                    uniqueness: { scope: [ :envelope_id, :year ] }
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }

  before_update :prevent_prior_month_modification

  private

  def prior_month?
    Date.new(year, month) < Date.current.beginning_of_month
  end

  def prevent_prior_month_modification
    if prior_month?
      errors.add(:base, "Cannot modify a prior month's budget")
      throw(:abort)
    end
  end
end
