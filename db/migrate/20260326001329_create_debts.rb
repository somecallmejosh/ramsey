class CreateDebts < ActiveRecord::Migration[8.1]
  def change
    create_table :debts do |t|
      t.string  :name, null: false
      t.integer :debt_type, null: false
      t.decimal :original_balance, precision: 10, scale: 2, null: false
      t.decimal :current_balance,  precision: 10, scale: 2, null: false
      t.decimal :minimum_payment,  precision: 10, scale: 2, null: false
      t.decimal :interest_rate,    precision: 5,  scale: 3
      t.integer :position, null: false
      t.date    :paid_off_at

      t.timestamps
    end

    add_index :debts, :position
  end
end
