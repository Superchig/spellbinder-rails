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

ActiveRecord::Schema.define(version: 2021_05_28_023728) do

  create_table "battle_states", force: :cascade do |t|
    t.string "left_hand"
    t.string "right_hand"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "health"
    t.integer "user_id"
    t.integer "battle_id"
    t.text "orders_left_gesture"
    t.string "orders_left_spell"
    t.string "orders_left_target"
    t.string "orders_right_gesture"
    t.string "orders_right_spell"
    t.string "orders_right_target"
    t.boolean "orders_finished"
    t.index ["battle_id"], name: "index_battle_states_on_battle_id"
    t.index ["user_id"], name: "index_battle_states_on_user_id"
  end

  create_table "battles", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "battles_users", force: :cascade do |t|
    t.integer "battle_id"
    t.integer "user_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["battle_id"], name: "index_battles_users_on_battle_id"
    t.index ["user_id"], name: "index_battles_users_on_user_id"
  end

  create_table "invitations", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "invitations_users", force: :cascade do |t|
    t.integer "invitation_id"
    t.integer "user_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["invitation_id"], name: "index_invitations_users_on_invitation_id"
    t.index ["user_id"], name: "index_invitations_users_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

end
