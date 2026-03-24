class CreateLunchLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :lunch_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.date :logged_on, null: false

      t.timestamps
    end
    add_index :lunch_logs, [ :user_id, :logged_on ], unique: true
  end
end
