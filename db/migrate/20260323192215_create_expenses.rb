class CreateExpenses < ActiveRecord::Migration[8.1]
  def change
    create_table :expenses do |t|
      t.references :envelope, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :note
      t.date :transacted_on, null: false

      t.timestamps
    end

    add_index :expenses, [:envelope_id, :transacted_on]

    execute "ALTER TABLE expenses ADD CONSTRAINT expenses_amount_positive CHECK (amount > 0)"
  end
end
