class CreateMeals < ActiveRecord::Migration[8.1]
  def change
    create_table :meals do |t|
      t.references :meal_plan, null: false, foreign_key: true
      t.integer :day_of_week,    null: false
      t.string  :dinner,         null: false
      t.string  :lunch,          null: false
      t.string  :prep_note
      t.decimal :estimated_cost, precision: 10, scale: 2

      t.timestamps
    end

    add_index :meals, [ :meal_plan_id, :day_of_week ], unique: true

    execute "ALTER TABLE meals ADD CONSTRAINT meals_day_of_week_range CHECK (day_of_week BETWEEN 0 AND 6)"
    execute "ALTER TABLE meals ADD CONSTRAINT meals_estimated_cost_non_negative CHECK (estimated_cost IS NULL OR estimated_cost >= 0)"
  end
end
