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

ActiveRecord::Schema[7.1].define(version: 2025_09_27_060110) do
  create_table "characters", force: :cascade do |t|
    t.string "name"
    t.text "personality_prompt"
    t.text "voice_settings"
    t.string "emoji"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "conversations", force: :cascade do |t|
    t.text "user_message", null: false
    t.text "ai_response", null: false
    t.string "session_id", null: false
    t.datetime "timestamp", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_conversations_on_created_at"
    t.index ["session_id"], name: "index_conversations_on_session_id"
    t.index ["timestamp"], name: "index_conversations_on_timestamp"
  end

  create_table "prompt_configs", force: :cascade do |t|
    t.string "key", null: false
    t.text "value", null: false
    t.string "config_type", null: false
    t.text "description"
    t.boolean "is_active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["config_type"], name: "index_prompt_configs_on_config_type"
    t.index ["is_active"], name: "index_prompt_configs_on_is_active"
    t.index ["key"], name: "index_prompt_configs_on_key", unique: true
  end

end
