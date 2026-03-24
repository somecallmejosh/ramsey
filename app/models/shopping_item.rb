class ShoppingItem < ApplicationRecord
  belongs_to :meal_plan

  validates :name, presence: true
end
