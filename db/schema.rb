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

ActiveRecord::Schema[8.1].define(version: 2026_03_24_185117) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

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

  create_table "lunch_logs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "logged_on", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "logged_on"], name: "index_lunch_logs_on_user_id_and_logged_on", unique: true
    t.index ["user_id"], name: "index_lunch_logs_on_user_id"
  end

  create_table "meal_plans", force: :cascade do |t|
    t.jsonb "ai_response"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.date "week_start", null: false
    t.index ["user_id"], name: "index_meal_plans_on_user_id"
    t.index ["week_start"], name: "index_meal_plans_on_week_start", unique: true
  end

  create_table "meals", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "day_of_week", null: false
    t.string "dinner", null: false
    t.decimal "estimated_cost", precision: 10, scale: 2
    t.string "lunch", null: false
    t.bigint "meal_plan_id", null: false
    t.string "prep_note"
    t.datetime "updated_at", null: false
    t.index ["meal_plan_id", "day_of_week"], name: "index_meals_on_meal_plan_id_and_day_of_week", unique: true
    t.index ["meal_plan_id"], name: "index_meals_on_meal_plan_id"
    t.check_constraint "day_of_week >= 0 AND day_of_week <= 6", name: "meals_day_of_week_range"
    t.check_constraint "estimated_cost IS NULL OR estimated_cost >= 0::numeric", name: "meals_estimated_cost_non_negative"
  end

  create_table "push_subscriptions", force: :cascade do |t|
    t.string "auth", null: false
    t.datetime "created_at", null: false
    t.string "endpoint", null: false
    t.string "p256dh", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["endpoint"], name: "index_push_subscriptions_on_endpoint", unique: true
    t.index ["user_id"], name: "index_push_subscriptions_on_user_id"
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

  create_table "shopping_items", force: :cascade do |t|
    t.boolean "checked", default: false, null: false
    t.datetime "created_at", null: false
    t.decimal "estimated_cost", precision: 10, scale: 2
    t.bigint "meal_plan_id", null: false
    t.string "name", null: false
    t.string "quantity"
    t.string "store", default: "Aldi"
    t.datetime "updated_at", null: false
    t.index ["meal_plan_id"], name: "index_shopping_items_on_meal_plan_id"
    t.check_constraint "estimated_cost IS NULL OR estimated_cost >= 0::numeric", name: "shopping_items_estimated_cost_non_negative"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "envelope_budgets", "envelopes"
  add_foreign_key "expenses", "envelopes"
  add_foreign_key "expenses", "users"
  add_foreign_key "lunch_logs", "users"
  add_foreign_key "meal_plans", "users"
  add_foreign_key "meals", "meal_plans"
  add_foreign_key "push_subscriptions", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "shopping_items", "meal_plans"
end
