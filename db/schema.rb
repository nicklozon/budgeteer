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

ActiveRecord::Schema[7.1].define(version: 2024_01_11_024211) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.string "title", null: false
    t.string "account_type", null: false
    t.string "currency", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "journal_entries", force: :cascade do |t|
    t.string "description", null: false
    t.integer "transaction_type", null: false
    t.integer "amount_in_cents", null: false
    t.decimal "exchange_rate", precision: 18, scale: 8
    t.integer "balance", null: false
    t.date "posted_date", null: false
    t.date "cleared_date", null: false
    t.integer "order"
    t.bigint "account_id", null: false
    t.bigint "matching_entry_id"
    t.bigint "next_entry_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "order"], name: "index_journal_entries_on_account_id_and_order"
    t.index ["account_id", "posted_date", "order"], name: "index_journal_entries_on_account_id_and_posted_date_and_order"
    t.index ["account_id"], name: "index_journal_entries_on_account_id"
    t.index ["matching_entry_id"], name: "index_journal_entries_on_matching_entry_id", unique: true
    t.index ["next_entry_id"], name: "index_journal_entries_on_next_entry_id"
    t.index ["posted_date"], name: "index_journal_entries_on_posted_date"
  end

  add_foreign_key "journal_entries", "accounts"
  add_foreign_key "journal_entries", "journal_entries", column: "matching_entry_id"
  add_foreign_key "journal_entries", "journal_entries", column: "next_entry_id"
end
