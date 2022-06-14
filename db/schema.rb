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

ActiveRecord::Schema.define(version: 2022_06_12_061013) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "categories", force: :cascade do |t|
    t.string "user"
    t.string "category_id"
    t.text "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "locations", force: :cascade do |t|
    t.string "user"
    t.string "location_id"
    t.text "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "material_stocks", force: :cascade do |t|
    t.string "user"
    t.string "material_id"
    t.string "action"
    t.integer "input_case"
    t.integer "input_package"
    t.integer "input_qty"
    t.integer "current_case"
    t.integer "current_package"
    t.integer "current_qty"
    t.integer "current_total"
    t.integer "arriving_case"
    t.integer "arriving_package"
    t.integer "arriving_qty"
    t.integer "arriving_total"
    t.integer "shipping_case"
    t.integer "shipping_package"
    t.integer "shipping_qty"
    t.integer "shipping_total"
    t.date "expire"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "materials", force: :cascade do |t|
    t.string "user"
    t.string "material_id"
    t.text "name"
    t.string "category_id"
    t.decimal "cost", precision: 9, scale: 2
    t.decimal "expense", precision: 9, scale: 2
    t.string "supplier_id"
    t.string "location_id"
    t.integer "qty_per_package"
    t.integer "package_per_case"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user", "material_id"], name: "for_upsert_materials", unique: true
  end

  create_table "product_stocks", force: :cascade do |t|
    t.string "user"
    t.string "product_id"
    t.string "action"
    t.integer "input_qty"
    t.integer "self_qty"
    t.integer "fba_qty"
    t.integer "total_qty"
    t.integer "arriving_qty"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "recorded_at"
  end

  create_table "product_tracks", force: :cascade do |t|
    t.bigint "product_id"
    t.integer "price"
    t.string "availability"
    t.integer "review_count"
    t.float "review_average"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_product_tracks_on_product_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "user"
    t.string "product_id"
    t.text "name"
    t.decimal "price"
    t.decimal "fee"
    t.decimal "expense"
    t.decimal "cost"
    t.decimal "profit"
    t.string "seller_id"
    t.string "fba_sku"
    t.string "self_sku"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "rakuten_url"
    t.string "rakuten_item_code"
    t.index ["user", "product_id"], name: "for_upsert_products", unique: true
  end

  create_table "recipes", force: :cascade do |t|
    t.string "user"
    t.string "product_id"
    t.string "material_id"
    t.integer "required_qty"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "reports", force: :cascade do |t|
    t.string "user"
    t.string "product_id"
    t.decimal "impression"
    t.decimal "click"
    t.decimal "click_through_rate"
    t.decimal "click_per_cost"
    t.decimal "cost"
    t.decimal "total_sale"
    t.decimal "adv_cost_of_sale"
    t.decimal "return_on_adv_spend"
    t.decimal "session"
    t.decimal "session_rate"
    t.decimal "page_view"
    t.decimal "page_view_rate"
    t.decimal "cart_box_rate"
    t.decimal "order_quantity"
    t.decimal "unit_session_rate"
    t.decimal "sale"
    t.decimal "total"
    t.date "recorded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sellers", force: :cascade do |t|
    t.string "user"
    t.string "seller_id"
    t.text "name"
    t.string "secret_key_id"
    t.string "aws_access_key_id"
    t.string "mws_auth_token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "suppliers", force: :cascade do |t|
    t.string "user"
    t.string "supplier_id"
    t.text "name"
    t.string "email"
    t.string "phone"
    t.string "fax"
    t.text "url"
    t.text "address"
    t.text "memo"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "admin_flg", default: false, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "product_tracks", "products"
end
