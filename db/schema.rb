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

ActiveRecord::Schema.define(version: 2022_02_18_120849) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "admin_invites", force: :cascade do |t|
    t.string "code"
    t.string "email"
    t.integer "role"
    t.boolean "is_verified"
    t.bigint "admin_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["admin_id"], name: "index_admin_invites_on_admin_id"
  end

  create_table "admins", force: :cascade do |t|
    t.string "provider", default: "email", null: false
    t.string "uid", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.boolean "allow_password_change", default: false
    t.datetime "remember_created_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.string "name"
    t.string "nickname"
    t.string "image"
    t.string "email"
    t.json "tokens"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "role", default: 3
    t.string "created_by", default: ""
    t.boolean "is_active", default: true
    t.index ["confirmation_token"], name: "index_admins_on_confirmation_token", unique: true
    t.index ["email"], name: "index_admins_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admins_on_reset_password_token", unique: true
    t.index ["uid", "provider"], name: "index_admins_on_uid_and_provider", unique: true
  end

  create_table "business_team_members", force: :cascade do |t|
    t.bigint "profile_id", null: false
    t.bigint "business_team_id", null: false
    t.boolean "is_active", default: true
    t.integer "role", default: 1
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["business_team_id"], name: "index_business_team_members_on_business_team_id"
    t.index ["profile_id"], name: "index_business_team_members_on_profile_id"
  end

  create_table "business_teams", force: :cascade do |t|
    t.bigint "profile_id", null: false
    t.bigint "business_id", null: false
    t.boolean "is_active", default: true
    t.string "team_name", default: "My Team"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["business_id"], name: "index_business_teams_on_business_id"
    t.index ["profile_id"], name: "index_business_teams_on_profile_id"
  end

  create_table "businesses", force: :cascade do |t|
    t.string "business_name"
    t.bigint "profile_id"
    t.string "industry"
    t.string "country_of_incorporation"
    t.string "staff_strength"
    t.string "registration_status"
    t.string "role_at_business"
    t.string "website"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "api_key"
    t.boolean "is_live", default: false
    t.string "test_key"
    t.index ["profile_id"], name: "index_businesses_on_profile_id"
  end

  create_table "cards", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "cart_items", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "cart_id", null: false
    t.integer "value", default: 0, null: false
    t.boolean "is_active", default: true, null: false
    t.integer "quantity", default: 0, null: false
    t.string "card_code", null: false
    t.boolean "checked_out", default: false, null: false
    t.boolean "is_deleted", default: false, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["cart_id"], name: "index_cart_items_on_cart_id"
  end

  create_table "carts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.bigint "profile_id", null: false
    t.boolean "checked_out", default: false, null: false
    t.boolean "is_active", default: true, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["profile_id"], name: "index_carts_on_profile_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "title"
    t.boolean "is_active", default: true, null: false
    t.integer "category_item_id"
    t.bigint "admin_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["admin_id"], name: "index_categories_on_admin_id"
  end

  create_table "category_items", force: :cascade do |t|
    t.string "item_id"
    t.integer "category_id"
    t.string "item_name"
    t.boolean "is_active", default: true, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "custom_gift_cards", force: :cascade do |t|
    t.string "__type", default: "type"
    t.string "caption"
    t.string "code"
    t.string "color", default: "#0277fe"
    t.string "currency", default: "NGN"
    t.string "desc"
    t.string "disclosures"
    t.decimal "discount", default: "0.0"
    t.string "domain"
    t.string "fee", default: "100.0"
    t.string "fontcolor", default: "#FFFFFF"
    t.boolean "is_variable", default: false
    t.string "iso", default: "ng"
    t.string "logo"
    t.integer "max_range", default: 0
    t.integer "min_range", default: 0
    t.string "sendcolor", default: "#FFFFFF"
    t.integer "values", array: true
    t.bigint "business_id"
    t.bigint "profile_id"
    t.boolean "is_active", default: true
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "is_disabled", default: false
    t.index ["business_id"], name: "index_custom_gift_cards_on_business_id"
    t.index ["profile_id"], name: "index_custom_gift_cards_on_profile_id"
    t.index ["values"], name: "index_custom_gift_cards_on_values", using: :gin
  end

  create_table "fx_histories", force: :cascade do |t|
    t.bigint "fx_id", null: false
    t.decimal "current_rate", precision: 30, scale: 2, null: false
    t.decimal "previous_rate", precision: 30, scale: 2, null: false
    t.decimal "current_exchange_rate", precision: 30, scale: 2, null: false
    t.decimal "previous_exchange_rate", precision: 30, scale: 2, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "admin_id", null: false
    t.index ["admin_id"], name: "index_fx_histories_on_admin_id"
    t.index ["fx_id"], name: "index_fx_histories_on_fx_id"
  end

  create_table "fxes", force: :cascade do |t|
    t.string "__type", default: "fx:#"
    t.string "name"
    t.string "currency"
    t.string "currency_symbol"
    t.string "iso"
    t.decimal "rate", default: "0.0", null: false
    t.decimal "exchange_rate", precision: 30, scale: 2, default: "0.0", null: false
    t.boolean "is_active", default: true, null: false
    t.boolean "is_public", default: false, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "ledger_histories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "ledger_id", null: false
    t.bigint "vendor_id", null: false
    t.bigint "profile_id", null: false
    t.jsonb "sender_details"
    t.string "preference"
    t.string "type"
    t.jsonb "details"
    t.string "category"
    t.decimal "balance", precision: 30, scale: 2
    t.decimal "amount", precision: 30, scale: 2
    t.decimal "actual_amount", precision: 30, scale: 2
    t.string "description"
    t.string "reference_code"
    t.string "channel"
    t.boolean "status", default: false
    t.boolean "is_active", default: false, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["ledger_id"], name: "index_ledger_histories_on_ledger_id"
    t.index ["profile_id"], name: "index_ledger_histories_on_profile_id"
    t.index ["vendor_id"], name: "index_ledger_histories_on_vendor_id"
  end

  create_table "ledgers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.bigint "profile_id", null: false
    t.bigint "vendor_id", null: false
    t.decimal "debit", precision: 30, scale: 2, default: "0.0", null: false
    t.decimal "credit", precision: 30, scale: 2, default: "0.0", null: false
    t.decimal "balance", precision: 30, scale: 2, default: "0.0", null: false
    t.boolean "use_credit", default: false
    t.boolean "is_test", default: false
    t.boolean "is_active", default: true, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["profile_id"], name: "index_ledgers_on_profile_id"
    t.index ["vendor_id"], name: "index_ledgers_on_vendor_id"
  end

  create_table "orders", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "card_order_id", null: false
    t.decimal "total_amount", precision: 30, scale: 2, default: "0.0", null: false
    t.decimal "amount", precision: 30, scale: 2, default: "0.0", null: false
    t.integer "quantity", default: 0, null: false
    t.string "gift_card_code", null: false
    t.jsonb "details", default: "{}"
    t.string "order_type", null: false
    t.string "status", null: false
    t.boolean "is_active"
    t.bigint "profile_id", null: false
    t.uuid "transaction_log_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["profile_id"], name: "index_orders_on_profile_id"
    t.index ["transaction_log_id"], name: "index_orders_on_transaction_log_id"
  end

  create_table "profiles", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "phone_number"
    t.string "profile_type"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "test_mode", default: true, null: false
    t.string "image"
    t.string "bvn"
    t.boolean "is_verified", default: false, null: false
    t.index ["user_id"], name: "index_profiles_on_user_id"
  end

  create_table "promo_winners", force: :cascade do |t|
    t.bigint "promo_id"
    t.bigint "profile_id", null: false
    t.uuid "transaction_log_id"
    t.boolean "is_active", default: false, null: false
    t.boolean "is_expired", default: false, null: false
    t.boolean "is_completed", default: false, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["profile_id"], name: "index_promo_winners_on_profile_id"
    t.index ["promo_id"], name: "index_promo_winners_on_promo_id"
  end

  create_table "promos", force: :cascade do |t|
    t.integer "final_count", default: 100
    t.integer "current_count", default: 0
    t.boolean "is_active", default: false, null: false
    t.decimal "discount", default: "0.5", null: false
    t.string "title", default: ""
    t.datetime "start_date", default: "2022-02-07 23:00:00", null: false
    t.datetime "end_date", default: "2022-02-15 23:59:59", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "team_invites", force: :cascade do |t|
    t.string "code"
    t.string "email"
    t.bigint "business_id", null: false
    t.bigint "business_team_id", null: false
    t.integer "role"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "is_verified", default: false, null: false
    t.index ["business_id"], name: "index_team_invites_on_business_id"
    t.index ["business_team_id"], name: "index_team_invites_on_business_team_id"
  end

  create_table "tmp_users", force: :cascade do |t|
    t.string "email"
    t.string "password"
    t.string "phone_number"
    t.string "tmp_token"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "transaction_logs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.bigint "profile_id", null: false
    t.string "gift_card_code"
    t.jsonb "details"
    t.integer "log_type", default: 0
    t.integer "status", default: 0
    t.boolean "is_active"
    t.uuid "reference_id"
    t.decimal "amount", precision: 30, scale: 2
    t.jsonb "transaction_rate"
    t.uuid "wallet_id"
    t.uuid "wallet_history_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.uuid "cart_id"
    t.integer "transaction_log_type", default: 0, null: false
    t.boolean "is_discounted", default: false, null: false
    t.decimal "discount_rate", default: "0.0"
    t.string "gift_card_name", default: ""
    t.uuid "ledger_id"
    t.uuid "ledger_history_id"
    t.index ["cart_id"], name: "index_transaction_logs_on_cart_id"
    t.index ["profile_id"], name: "index_transaction_logs_on_profile_id"
    t.index ["wallet_history_id"], name: "index_transaction_logs_on_wallet_history_id"
    t.index ["wallet_id"], name: "index_transaction_logs_on_wallet_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "provider", default: "email", null: false
    t.string "uid", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.boolean "allow_password_change", default: false
    t.datetime "remember_created_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.string "name"
    t.string "nickname"
    t.string "image"
    t.string "email"
    t.json "tokens"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["uid", "provider"], name: "index_users_on_uid_and_provider", unique: true
  end

  create_table "vendor_allowed_giftcard_sources", force: :cascade do |t|
    t.bigint "vendor_id", null: false
    t.string "sources", array: true
    t.bigint "created_by_id"
    t.boolean "is_active", default: true, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["created_by_id"], name: "index_vendor_allowed_giftcard_sources_on_created_by_id"
    t.index ["vendor_id"], name: "index_vendor_allowed_giftcard_sources_on_vendor_id"
  end

  create_table "vendors", force: :cascade do |t|
    t.string "business_name"
    t.bigint "profile_id", null: false
    t.string "industry"
    t.string "registration_status"
    t.string "country_of_incorporation"
    t.boolean "is_live", default: true, null: false
    t.string "live_key"
    t.string "test_key"
    t.boolean "is_authorised", default: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["profile_id"], name: "index_vendors_on_profile_id"
  end

  create_table "wallet_histories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.bigint "profile_id", null: false
    t.jsonb "sender_details"
    t.string "preference"
    t.string "type"
    t.jsonb "details"
    t.string "category"
    t.decimal "amount", precision: 30, scale: 2
    t.decimal "balance", precision: 30, scale: 2
    t.decimal "commission", precision: 30, scale: 2
    t.decimal "actual_amount", precision: 30, scale: 2
    t.string "description"
    t.string "reference_code"
    t.string "channel"
    t.boolean "status", default: false
    t.boolean "is_active"
    t.uuid "wallet_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["profile_id"], name: "index_wallet_histories_on_profile_id"
    t.index ["wallet_id"], name: "index_wallet_histories_on_wallet_id"
  end

  create_table "wallets", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.bigint "profile_id", null: false
    t.decimal "cleared_balance", precision: 30, scale: 2, default: "0.0"
    t.decimal "available_balance", precision: 30, scale: 2, default: "0.0"
    t.boolean "is_active"
    t.string "profile_type"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "is_test", default: false, null: false
    t.bigint "business_id"
    t.index ["business_id"], name: "index_wallets_on_business_id"
    t.index ["profile_id"], name: "index_wallets_on_profile_id"
  end

  add_foreign_key "admin_invites", "admins"
  add_foreign_key "business_team_members", "business_teams"
  add_foreign_key "business_team_members", "profiles"
  add_foreign_key "business_teams", "businesses"
  add_foreign_key "business_teams", "profiles"
  add_foreign_key "businesses", "profiles"
  add_foreign_key "cart_items", "carts"
  add_foreign_key "carts", "profiles"
  add_foreign_key "categories", "admins"
  add_foreign_key "fx_histories", "admins"
  add_foreign_key "fx_histories", "fxes"
  add_foreign_key "ledger_histories", "ledgers"
  add_foreign_key "ledger_histories", "profiles"
  add_foreign_key "ledger_histories", "vendors"
  add_foreign_key "ledgers", "profiles"
  add_foreign_key "ledgers", "vendors"
  add_foreign_key "orders", "profiles"
  add_foreign_key "profiles", "users"
  add_foreign_key "team_invites", "business_teams"
  add_foreign_key "team_invites", "businesses"
  add_foreign_key "transaction_logs", "carts"
  add_foreign_key "transaction_logs", "profiles"
  add_foreign_key "vendor_allowed_giftcard_sources", "admins", column: "created_by_id"
  add_foreign_key "vendor_allowed_giftcard_sources", "vendors"
  add_foreign_key "vendors", "profiles"
  add_foreign_key "wallet_histories", "profiles"
  add_foreign_key "wallets", "businesses"
  add_foreign_key "wallets", "profiles"
end
