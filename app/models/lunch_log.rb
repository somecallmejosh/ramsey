class LunchLog < ApplicationRecord
  SAVINGS_PER_LUNCH = 20

  belongs_to :user

  validates :logged_on, presence: true, uniqueness: { scope: :user_id, message: "That day is already logged." }
  validate  :logged_on_not_in_future

  scope :for_month, ->(year, month) {
    where(logged_on: Date.new(year, month).all_month)
  }

  private

  def logged_on_not_in_future
    return if logged_on.blank? || logged_on <= Date.current
    errors.add(:logged_on, "You can't log a day that hasn't happened yet.")
  end
end
