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

ActiveRecord::Schema[8.2].define(version: 2025_01_01_120001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "unaccent"

  create_text_search_configuration(
    "simple_unaccent",
    parser: "default",
    force: :cascade,
    mappings: {
      ["asciiword", "numword", "email", "url", "host", "sfloat", "version", "hword_numpart", "hword_asciipart", "numhword", "asciihword", "url_path", "file", "float", "int", "uint"] => ["simple"],
      ["word", "hword_part", "hword"] => ["unaccent", "simple"]
    }
  )

  create_table "articles", force: :cascade do |t|
    t.text "title", null: false
    t.virtual "title_tsvector", type: :tsvector, as: "to_tsvector('simple_unaccent'::regconfig, title)", stored: true
  end
end
