# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20200303165827) do

  create_table "fine_print_contracts", force: :cascade do |t|
    t.string "name", null: false
    t.integer "version"
    t.string "title", null: false
    t.text "content", null: false
    t.integer "company_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["name", "version"], name: "index_fine_print_contracts_on_name_and_version", unique: true
  end

  create_table "fine_print_signatures", force: :cascade do |t|
    t.integer "contract_id", null: false
    t.string "user_type", null: false
    t.integer "user_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "is_implicit", default: false, null: false
    t.index ["contract_id"], name: "index_fine_print_signatures_on_contract_id"
    t.index ["user_id", "user_type", "contract_id"], name: "index_fine_print_s_on_u_id_and_u_type_and_c_id", unique: true
  end

  create_table "sms_messages", force: :cascade do |t|
    t.string "to"
    t.text "body"
    t.integer "company_id"
    t.integer "user_id"
    t.integer "customer_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "from"
    t.string "sid"
  end

  create_table "twilio_numbers", force: :cascade do |t|
    t.string "phone_number"
    t.integer "company_id"
    t.string "sid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "first_name", default: "", null: false
    t.string "last_name", default: "", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "company_id", null: false
    t.integer "customer_id"
    t.string "role", default: "admin", null: false
    t.string "phone"
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "temporary_password"
    t.text "device_ids"
    t.string "time_zone", default: "Eastern Time (US & Canada)"
    t.boolean "view_events"
    t.boolean "edit_events"
    t.boolean "view_wallet_types"
    t.boolean "edit_wallet_types"
    t.boolean "view_accounts"
    t.boolean "edit_accounts"
    t.boolean "view_users"
    t.boolean "edit_users"
    t.boolean "view_atms"
    t.boolean "can_quick_pay"
    t.text "admin_event_ids"
    t.boolean "can_pay_from_corporate"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

end
