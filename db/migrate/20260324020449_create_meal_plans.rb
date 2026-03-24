class CreateMealPlans < ActiveRecord::Migration[8.1]
  def change
    create_table :meal_plans do |t|
      t.references :user, null: false, foreign_key: true
      t.date     :week_start,   null: false
      t.datetime :confirmed_at
      t.jsonb    :ai_response

      t.timestamps
    end

    add_index :meal_plans, :week_start, unique: true
  end
end
