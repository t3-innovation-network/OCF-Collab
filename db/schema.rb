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

ActiveRecord::Schema[8.0].define(version: 2024_12_12_072051) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "btree_gin"
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"
  enable_extension "vector"

  create_table "code_sets", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.string "external_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_code_sets_on_external_id", unique: true
  end

  create_table "codes", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.string "description"
    t.uuid "code_set_id", null: false
    t.string "name", null: false
    t.string "value", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code_set_id", "value"], name: "index_codes_on_code_set_id_and_value", unique: true
    t.index ["code_set_id"], name: "index_codes_on_code_set_id"
  end

  create_table "competencies", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "container_id", null: false
    t.text "competency_text", null: false
    t.text "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "external_id"
    t.string "competency_category"
    t.string "competency_label"
    t.string "keywords", default: [], array: true
    t.string "html_url"
    t.string "all_text", default: "", null: false
    t.tsvector "all_text_tsv"
    t.vector "all_text_embedding"
    t.index ["all_text_tsv"], name: "index_competencies_on_all_text_tsv", using: :gin
    t.index ["container_id"], name: "index_competencies_on_container_id"
    t.index ["external_id"], name: "index_competencies_on_external_id", unique: true
  end

  create_table "competency_contextualizing_objects", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "competency_id", null: false
    t.uuid "contextualizing_object_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["competency_id", "contextualizing_object_id"], name: "index_competency_contextualizing_objects", unique: true
  end

  create_table "contact_points", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "node_directory_id"
    t.string "email", null: false
    t.string "name"
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["node_directory_id"], name: "index_contact_points_on_node_directory_id"
  end

  create_table "containers", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "node_directory_id", null: false
    t.string "node_directory_s3_key", null: false
    t.string "external_id", null: false
    t.string "name", limit: 1000, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "concept_keywords", array: true
    t.string "attribution_name", null: false
    t.string "attribution_url", null: false
    t.string "provider_meta_model", null: false
    t.string "beneficiary_rights", null: false
    t.string "registry_rights", null: false
    t.string "data_url"
    t.string "type", default: "CompetencyFramework", null: false
    t.string "html_url"
    t.index ["data_url"], name: "index_containers_on_data_url"
    t.index ["external_id"], name: "index_containers_on_external_id"
    t.index ["node_directory_id"], name: "index_containers_on_node_directory_id"
    t.index ["type"], name: "index_containers_on_type"
  end

  create_table "contextualizing_object_codes", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "code_id", null: false
    t.uuid "contextualizing_object_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code_id", "contextualizing_object_id"], name: "index_contextualizing_object_codes", unique: true
  end

  create_table "contextualizing_objects", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.string "coded_notation"
    t.string "data_url", null: false
    t.string "description"
    t.string "external_id", null: false
    t.string "name", null: false
    t.string "type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_contextualizing_objects_on_external_id", unique: true
    t.index ["type"], name: "index_contextualizing_objects_on_type"
  end

  create_table "node_directories", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "s3_bucket", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "external_id", null: false
    t.string "logo_url"
    t.string "pna_url"
    t.string "s3_region", default: "us-east-1"
    t.string "competency_mapping_name"
  end

  create_table "oauth_access_grants", force: :cascade do |t|
    t.bigint "resource_owner_id", null: false
    t.bigint "application_id", null: false
    t.string "token", null: false
    t.integer "expires_in", null: false
    t.text "redirect_uri", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "revoked_at", precision: nil
    t.string "scopes", default: "", null: false
    t.index ["application_id"], name: "index_oauth_access_grants_on_application_id"
    t.index ["resource_owner_id"], name: "index_oauth_access_grants_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_grants_on_token", unique: true
  end

  create_table "oauth_access_tokens", force: :cascade do |t|
    t.bigint "resource_owner_id"
    t.bigint "application_id", null: false
    t.string "token", null: false
    t.string "refresh_token"
    t.integer "expires_in"
    t.datetime "revoked_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.string "scopes"
    t.string "previous_refresh_token", default: "", null: false
    t.index ["application_id"], name: "index_oauth_access_tokens_on_application_id"
    t.index ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true
    t.index ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_tokens_on_token", unique: true
  end

  create_table "oauth_applications", force: :cascade do |t|
    t.string "name", null: false
    t.string "uid", null: false
    t.string "secret", null: false
    t.text "redirect_uri"
    t.string "scopes", default: "", null: false
    t.boolean "confidential", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "node_directory_id"
    t.index ["node_directory_id"], name: "index_oauth_applications_on_node_directory_id"
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true
  end

  add_foreign_key "codes", "code_sets", on_delete: :cascade
  add_foreign_key "competencies", "containers", on_delete: :cascade
  add_foreign_key "competency_contextualizing_objects", "competencies", on_delete: :cascade
  add_foreign_key "competency_contextualizing_objects", "contextualizing_objects", on_delete: :cascade
  add_foreign_key "contextualizing_object_codes", "codes", on_delete: :cascade
  add_foreign_key "contextualizing_object_codes", "contextualizing_objects", on_delete: :cascade
  add_foreign_key "oauth_access_grants", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_tokens", "oauth_applications", column: "application_id"
end
