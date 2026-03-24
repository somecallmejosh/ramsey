class Meal < ApplicationRecord
  belongs_to :meal_plan

  validates :dinner,     presence: true
  validates :lunch,      presence: true
  validates :day_of_week,
            inclusion:  { in: 0..6 },
            uniqueness: { scope: :meal_plan_id }

  DAY_NAMES = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday].freeze

  def day_name
    DAY_NAMES[day_of_week]
  end
end
