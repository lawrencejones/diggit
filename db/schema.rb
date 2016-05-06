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

ActiveRecord::Schema.define(version: 20160506125119) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "projects", force: :cascade do |t|
    t.string  "gh_path",                   limit: 126,                null: false
    t.boolean "watch",                                 default: true
    t.text    "ssh_public_key"
    t.binary  "encrypted_ssh_private_key"
    t.binary  "ssh_initialization_vector"
  end

  add_index "projects", ["gh_path"], name: "index_projects_on_gh_path", unique: true, using: :btree

  create_table "pull_analyses", force: :cascade do |t|
    t.integer  "project_id"
    t.integer  "pull",                             null: false
    t.json     "comments",         default: [],    null: false
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
    t.text     "base",                             null: false
    t.text     "head",                             null: false
    t.boolean  "pushed_to_github", default: false, null: false
  end

  add_index "pull_analyses", ["project_id", "pull", "base", "head"], name: "index_pull_analyses_on_project_id_and_pull_and_base_and_head", unique: true, using: :btree
  add_index "pull_analyses", ["project_id"], name: "index_pull_analyses_on_project_id", using: :btree

  create_table "que_jobs", id: false, force: :cascade do |t|
    t.integer  "priority",    limit: 2, default: 100,                   null: false
    t.datetime "run_at",                default: '2016-04-07 10:06:35', null: false
    t.integer  "job_id",      limit: 8, default: 0,                     null: false
    t.text     "job_class",                                             null: false
    t.json     "args",                  default: [],                    null: false
    t.integer  "error_count",           default: 0,                     null: false
    t.text     "last_error"
    t.text     "queue",                 default: "",                    null: false
  end

  add_foreign_key "pull_analyses", "projects"
end
