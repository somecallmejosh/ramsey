class CreateDebtPayments < ActiveRecord::Migration[8.1]
  def change
    create_table :debt_payments do |t|
      t.references :debt, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.decimal :amount,        precision: 10, scale: 2, null: false
      t.decimal :balance_after, precision: 10, scale: 2, null: false
      t.date    :paid_on,       null: false
      t.string  :note

      t.timestamps
    end
  end
end
