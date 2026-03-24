class CreateEnvelopeBudgets < ActiveRecord::Migration[8.1]
  def change
    create_table :envelope_budgets do |t|
      t.references :envelope, null: false, foreign_key: true
      t.integer :year, null: false
      t.integer :month, null: false
      t.decimal :amount, precision: 10, scale: 2, null: false

      t.timestamps
    end

    add_index :envelope_budgets, [:envelope_id, :year, :month], unique: true

    execute "ALTER TABLE envelope_budgets ADD CONSTRAINT envelope_budgets_amount_non_negative CHECK (amount >= 0)"
  end
end
