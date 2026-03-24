# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_03_23_192215) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "envelope_budgets", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.bigint "envelope_id", null: false
    t.integer "month", null: false
    t.datetime "updated_at", null: false
    t.integer "year", null: false
    t.index ["envelope_id", "year", "month"], name: "index_envelope_budgets_on_envelope_id_and_year_and_month", unique: true
    t.index ["envelope_id"], name: "index_envelope_budgets_on_envelope_id"
    t.check_constraint "amount >= 0::numeric", name: "envelope_budgets_amount_non_negative"
  end

  create_table "envelopes", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
  end

  create_table "expenses", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.bigint "envelope_id", null: false
    t.string "note"
    t.date "transacted_on", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["envelope_id", "transacted_on"], name: "index_expenses_on_envelope_id_and_transacted_on"
    t.index ["envelope_id"], name: "index_expenses_on_envelope_id"
    t.index ["user_id"], name: "index_expenses_on_user_id"
    t.check_constraint "amount > 0::numeric", name: "expenses_amount_positive"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "last_active_at"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "envelope_budgets", "envelopes"
  add_foreign_key "expenses", "envelopes"
  add_foreign_key "expenses", "users"
  add_foreign_key "sessions", "users"
end
