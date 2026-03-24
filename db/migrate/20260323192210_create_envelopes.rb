class CreateEnvelopes < ActiveRecord::Migration[8.1]
  def change
    create_table :envelopes do |t|
      t.string :name, null: false
      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true

      t.timestamps
    end
  end
end
