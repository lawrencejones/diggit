# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20160331211012) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "que_jobs", id: false, force: :cascade do |t|
    t.integer  "priority",    limit: 2, default: 100,                   null: false
    t.datetime "run_at",                default: '2016-03-31 22:05:52', null: false
    t.integer  "job_id",      limit: 8, default: 0,                     null: false
    t.text     "job_class",                                             null: false
    t.json     "args",                  default: [],                    null: false
    t.integer  "error_count",           default: 0,                     null: false
    t.text     "last_error"
    t.text     "queue",                 default: "",                    null: false
  end

  create_table "projects", force: :cascade do |t|
    t.string "github_path", limit: 126, null: false
  end

  add_index "projects", ["github_path"], name: "index_projects_on_github_path", unique: true, using: :btree

end
