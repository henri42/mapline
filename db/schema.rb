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

ActiveRecord::Schema[8.0].define(version: 2026_07_12_100002) do
  create_table "feature_states", force: :cascade do |t|
    t.integer "map_feature_id", null: false
    t.integer "key_date_id", null: false
    t.json "geometry", null: false
    t.json "style_override"
    t.boolean "visible", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key_date_id"], name: "index_feature_states_on_key_date_id"
    t.index ["map_feature_id", "key_date_id"], name: "index_feature_states_on_map_feature_id_and_key_date_id", unique: true
    t.index ["map_feature_id"], name: "index_feature_states_on_map_feature_id"
  end

  create_table "key_dates", force: :cascade do |t|
    t.integer "mapline_id", null: false
    t.integer "year", null: false
    t.integer "month"
    t.integer "day"
    t.integer "sort_key", null: false
    t.string "label"
    t.string "title"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["mapline_id", "sort_key"], name: "index_key_dates_on_mapline_id_and_sort_key", unique: true
    t.index ["mapline_id"], name: "index_key_dates_on_mapline_id"
  end

  create_table "map_features", force: :cascade do |t|
    t.integer "mapline_id", null: false
    t.string "feature_type", null: false
    t.string "name"
    t.integer "z_index", default: 0, null: false
    t.json "style", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["mapline_id"], name: "index_map_features_on_mapline_id"
  end

  create_table "maplines", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "title", null: false
    t.string "slug", null: false
    t.text "description"
    t.string "status", default: "draft", null: false
    t.float "center_lng", default: 0.0, null: false
    t.float "center_lat", default: 20.0, null: false
    t.float "zoom", default: 1.5, null: false
    t.datetime "published_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_maplines_on_slug", unique: true
    t.index ["user_id"], name: "index_maplines_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "sources", force: :cascade do |t|
    t.integer "mapline_id", null: false
    t.string "title", null: false
    t.string "url"
    t.string "author"
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["mapline_id"], name: "index_sources_on_mapline_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "display_name", null: false
    t.text "bio"
    t.string "website_url"
    t.string "slug", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["slug"], name: "index_users_on_slug", unique: true
  end

  add_foreign_key "feature_states", "key_dates"
  add_foreign_key "feature_states", "map_features"
  add_foreign_key "key_dates", "maplines"
  add_foreign_key "map_features", "maplines"
  add_foreign_key "maplines", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "sources", "maplines"
end
