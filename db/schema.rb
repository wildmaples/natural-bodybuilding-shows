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

ActiveRecord::Schema[8.0].define(version: 2025_12_28_161005) do
  create_table "events", force: :cascade do |t|
    t.string "name", null: false
    t.date "date"
    t.string "location"
    t.string "state"
    t.string "url"
    t.string "federation", null: false
    t.date "archived_on"
    t.text "divisions"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["date"], name: "index_events_on_date"
    t.index ["federation"], name: "index_events_on_federation"
    t.index ["name", "date", "federation"], name: "index_events_uniqueness", unique: true
  end
end
