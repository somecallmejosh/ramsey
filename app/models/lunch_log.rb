class LunchLog < ApplicationRecord
  SAVINGS_PER_LUNCH = 8

  belongs_to :user

  validates :logged_on, presence: true, uniqueness: { scope: :user_id }

  scope :for_month, ->(year, month) {
    where(logged_on: Date.new(year, month).all_month)
  }
end
