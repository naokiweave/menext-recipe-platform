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

ActiveRecord::Schema[8.0].define(version: 2025_01_01_000003) do
  create_table "recipe_tags", force: :cascade do |t|
    t.integer "recipe_id", null: false
    t.integer "tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["recipe_id", "tag_id"], name: "index_recipe_tags_on_recipe_id_and_tag_id", unique: true
    t.index ["recipe_id"], name: "index_recipe_tags_on_recipe_id"
    t.index ["tag_id"], name: "index_recipe_tags_on_tag_id"
  end

  create_table "recipes", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.string "video_url"
    t.string "thumbnail_url"
    t.string "industry", null: false
    t.string "purpose", null: false
    t.string "difficulty_level", null: false
    t.integer "duration_minutes", null: false
    t.string "access_level", default: "free", null: false
    t.integer "preview_seconds"
    t.text "ingredients"
    t.text "instructions"
    t.text "tips"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "hls_master_url"
    t.string "thumbnail_s3_key"
    t.text "video_qualities"
    t.string "processing_status", default: "pending"
    t.text "processing_error"
    t.datetime "processed_at"
    t.index ["access_level"], name: "index_recipes_on_access_level"
    t.index ["difficulty_level"], name: "index_recipes_on_difficulty_level"
    t.index ["hls_master_url"], name: "index_recipes_on_hls_master_url"
    t.index ["industry"], name: "index_recipes_on_industry"
    t.index ["processing_status"], name: "index_recipes_on_processing_status"
    t.index ["purpose"], name: "index_recipes_on_purpose"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  add_foreign_key "recipe_tags", "recipes"
  add_foreign_key "recipe_tags", "tags"
end
