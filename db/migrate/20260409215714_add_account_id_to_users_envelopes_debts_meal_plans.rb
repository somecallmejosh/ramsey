class AddAccountIdToUsersEnvelopesDebtsMealPlans < ActiveRecord::Migration[8.1]
  def change
    add_reference :users, :account, null: true, foreign_key: true
    add_reference :envelopes, :account, null: true, foreign_key: true
    add_reference :debts, :account, null: true, foreign_key: true
    add_reference :meal_plans, :account, null: true, foreign_key: true
  end
end
