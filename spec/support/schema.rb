# frozen_string_literal: true

# Create database tables needed for testing
ActiveRecord::Schema.define do
  # User table for associations
  create_table :users, force: true do |t|
    t.integer "group_id", default: 1, null: false
    t.string "login", limit: 100
    t.string "nickname", limit: 100, default: "", null: false
    t.string "password", limit: 60, null: false
    t.string "email", null: false
    t.string "phone", limit: 100
    t.string "icq", limit: 15, default: "", null: false
    t.datetime "regdate", null: false
    t.datetime "logdate", null: false
    t.date "birthdate", null: false
    t.boolean "is_locked", default: false, null: false
    t.integer "is_locked2", limit: 1, default: 0, null: false
    t.boolean "is_logged_once", default: false, null: false
    t.integer "rating", default: 0, null: false
    t.integer "points", default: 0, null: false
    t.string "last_ip", limit: 15, default: "", null: false
    t.string "status", default: "", null: false
    t.datetime "status_date"
    t.integer "invited_by"
    t.datetime "invdate"
    t.timestamps
  end

  # RBK Money tables
  create_table :rbk_money_customers, force: true do |t|
    t.string "rbk_id", null: false
    t.integer "user_id", null: false
    t.json "payload"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "access_token", null: false
    t.datetime "access_token_expired_at"
    t.index ["user_id"], name: "index_rbk_money_customers_on_user_id"
  end

  create_table :rbk_payment_cards, force: true do |t|
    t.string "rbk_id", null: false
    t.string "bin", null: false
    t.string "last_digits", null: false
    t.string "rbk_customer_id", null: false
    t.string "brand", null: false
    t.integer "card_type", default: 0, null: false
    t.json "payload", null: false
    t.index ["rbk_customer_id"], name: "index_rbk_payment_cards_on_rbk_customer_id"
  end

  create_table :rbk_identities, force: true do |t|
    t.string "rbk_id", null: false
    t.json "payload"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "current", default: false, null: false
  end

  create_table :rbk_wallets, force: true do |t|
    t.string "rbk_id", null: false
    t.bigint "rbk_identity_id", null: false
    t.json "payload"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "current", default: false, null: false
    t.index ["rbk_identity_id"], name: "fk_rails_b1e89ecd83"
  end

  create_table :rbk_money_invoices, force: true do |t|
    t.integer "amount_in_cents", null: false
    t.string "rbk_invoice_id"
    t.string "description"
    t.string "state"
    t.json "payload"
    t.bigint "order_public_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "access_token"
    t.index ["order_public_id"], name: "index_rbk_money_invoices_on_order_public_id", unique: true
  end

  create_table :rbk_money_payments, force: true do |t|
    t.string "rbk_id", null: false
    t.string "state", null: false
    t.integer "amount_in_cents", null: false
    t.json "payload"
    t.json "refund_payload"
    t.bigint "order_public_id", null: false
    t.bigint "rbk_money_invoice_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_public_id"], name: "index_rbk_money_payments_on_order_public_id", unique: true
    t.index ["rbk_money_invoice_id"], name: "index_rbk_money_payments_on_rbk_money_invoice_id"
  end

  create_table :rbk_payouts, force: true do |t|
    t.bigint "rbk_payout_destination_id", null: false
    t.bigint "rbk_wallet_id", null: false
    t.integer "amount_cents", null: false
    t.json "payload"
    t.string "rbk_status", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "rbk_id", null: false
    t.index ["rbk_payout_destination_id"], name: "fk_rails_eb1172faa0"
    t.index ["rbk_wallet_id"], name: "fk_rails_4be66d8283"
  end

  create_table :rbk_payout_destinations, force: true do |t|
    t.bigint "rbk_identity_id", null: false
    t.string "rbk_id", null: false
    t.string "public_id", null: false
    t.string "card_brand", null: false
    t.string "card_bin", null: false
    t.string "card_suffix", null: false
    t.string "payment_token", null: false
    t.string "rbk_status", null: false
    t.json "payload", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["rbk_identity_id"], name: "fk_rails_d31b9211b9"
  end
end