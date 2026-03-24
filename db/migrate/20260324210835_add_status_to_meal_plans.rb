class AddStatusToMealPlans < ActiveRecord::Migration[8.1]
  def change
    add_column :meal_plans, :status, :string, default: "pending", null: false
    add_column :meal_plans, :error_message, :text
  end
end
