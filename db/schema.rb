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

ActiveRecord::Schema[8.1].define(version: 2026_09_10_142927) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "medication_checks", force: :cascade do |t|
    t.date "check_date", null: false
    t.datetime "created_at", null: false
    t.bigint "medication_timing_id", null: false
    t.datetime "updated_at", null: false
    t.index ["medication_timing_id", "check_date"], name: "index_medication_checks_on_medication_timing_id_and_check_date", unique: true
    t.index ["medication_timing_id"], name: "index_medication_checks_on_medication_timing_id"
  end

  create_table "medication_timings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "meal_timing", null: false
    t.bigint "medication_id", null: false
    t.bigint "time_period_id", null: false
    t.datetime "updated_at", null: false
    t.index ["medication_id", "time_period_id"], name: "index_medication_timings_on_medication_id_and_time_period_id", unique: true
    t.index ["medication_id"], name: "index_medication_timings_on_medication_id"
    t.index ["time_period_id"], name: "index_medication_timings_on_time_period_id"
  end

  create_table "medications", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "dosage", null: false
    t.date "end_date"
    t.string "name", null: false
    t.date "start_date", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_medications_on_user_id"
  end

  create_table "time_periods", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "position", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "nickname"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "medication_checks", "medication_timings"
  add_foreign_key "medication_timings", "medications"
  add_foreign_key "medication_timings", "time_periods"
  add_foreign_key "medications", "users"
end
