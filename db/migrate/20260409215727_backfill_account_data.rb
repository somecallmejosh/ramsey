class BackfillAccountData < ActiveRecord::Migration[8.1]
  def up
    account = execute("INSERT INTO accounts (name, created_at, updated_at) VALUES ('Briley Household', NOW(), NOW()) RETURNING id").first
    account_id = account["id"]

    execute("UPDATE users SET account_id = #{account_id}")
    execute("UPDATE envelopes SET account_id = #{account_id}")
    execute("UPDATE debts SET account_id = #{account_id}")
    execute("UPDATE meal_plans SET account_id = #{account_id}")
  end

  def down
    execute("UPDATE users SET account_id = NULL")
    execute("UPDATE envelopes SET account_id = NULL")
    execute("UPDATE debts SET account_id = NULL")
    execute("UPDATE meal_plans SET account_id = NULL")
    execute("DELETE FROM accounts")
  end
end
