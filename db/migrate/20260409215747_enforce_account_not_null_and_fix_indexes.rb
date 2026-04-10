class EnforceAccountNotNullAndFixIndexes < ActiveRecord::Migration[8.1]
  def change
    change_column_null :users, :account_id, false
    change_column_null :envelopes, :account_id, false
    change_column_null :debts, :account_id, false
    change_column_null :meal_plans, :account_id, false

    remove_index :meal_plans, :week_start
    add_index :meal_plans, [ :account_id, :week_start ], unique: true
  end
end
