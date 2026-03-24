class ShoppingItem < ApplicationRecord
  STORES = %w[Aldi Walmart Costco Target Other].freeze

  belongs_to :meal_plan

  validates :name, presence: true
end
