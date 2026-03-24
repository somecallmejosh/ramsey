class CreateShoppingItems < ActiveRecord::Migration[8.1]
  def change
    create_table :shopping_items do |t|
      t.references :meal_plan, null: false, foreign_key: true
      t.string  :name,           null: false
      t.string  :quantity
      t.decimal :estimated_cost, precision: 10, scale: 2
      t.boolean :checked,        null: false, default: false
      t.string  :store,          default: "Aldi"

      t.timestamps
    end

    execute "ALTER TABLE shopping_items ADD CONSTRAINT shopping_items_estimated_cost_non_negative CHECK (estimated_cost IS NULL OR estimated_cost >= 0)"
  end
end
