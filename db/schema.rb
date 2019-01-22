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

ActiveRecord::Schema.define(version: 0) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_buffercache"
  enable_extension "pg_stat_statements"
  enable_extension "plpgsql"

  create_table "__EFMigrationsHistory", primary_key: "MigrationId", id: :string, limit: 150, force: :cascade do |t|
    t.string "ProductVersion", limit: 32, null: false
  end

  create_table "access_request", id: :serial, force: :cascade do |t|
    t.text "email_address"
    t.text "first_name"
    t.text "last_name"
    t.text "organisation"
    t.text "reason"
    t.datetime "request_date_utc", null: false
    t.integer "requester_id"
    t.integer "status", null: false
    t.text "requester_email"
    t.index ["requester_id"], name: "IX_access_request_requester_id"
  end

  create_table "course", id: :serial, force: :cascade do |t|
    t.text "age_range"
    t.text "course_code"
    t.text "name"
    t.text "profpost_flag"
    t.text "program_type"
    t.integer "qualification", null: false
    t.datetime "start_date"
    t.text "study_mode"
    t.integer "accrediting_provider_id"
    t.integer "provider_id", default: 0, null: false
    t.text "modular"
    t.integer "english"
    t.integer "maths"
    t.integer "science"
    t.index ["accrediting_provider_id"], name: "IX_course_accrediting_provider_id"
    t.index ["provider_id", "course_code"], name: "IX_course_provider_id_course_code", unique: true
  end

  create_table "course_enrichment", id: :serial, force: :cascade do |t|
    t.integer "created_by_user_id"
    t.datetime "created_timestamp_utc", null: false
    t.text "provider_code", null: false
    t.jsonb "json_data"
    t.datetime "last_published_timestamp_utc"
    t.integer "status", null: false
    t.text "ucas_course_code", null: false
    t.integer "updated_by_user_id"
    t.datetime "updated_timestamp_utc", null: false
    t.index ["created_by_user_id"], name: "IX_course_enrichment_created_by_user_id"
    t.index ["updated_by_user_id"], name: "IX_course_enrichment_updated_by_user_id"
  end

  create_table "course_site", id: :serial, force: :cascade do |t|
    t.date "applications_accepted_from"
    t.integer "course_id"
    t.text "publish"
    t.integer "site_id"
    t.text "status"
    t.text "vac_status"
    t.index ["course_id"], name: "IX_course_site_course_id"
    t.index ["site_id"], name: "IX_course_site_site_id"
  end

  create_table "course_subject", id: :serial, force: :cascade do |t|
    t.integer "course_id"
    t.integer "subject_id"
    t.index ["course_id"], name: "IX_course_subject_course_id"
    t.index ["subject_id"], name: "IX_course_subject_subject_id"
  end

  create_table "nctl_organisation", id: :serial, force: :cascade do |t|
    t.text "name"
    t.text "nctl_id", null: false
    t.integer "organisation_id"
    t.index ["organisation_id"], name: "IX_nctl_organisation_organisation_id"
  end

  create_table "organisation", id: :integer, force: :cascade do |t|
    t.text "name"
    t.text "org_id"
    t.index ["org_id"], name: "IX_mc_organisation_org_id", unique: true
    t.index ["org_id"], name: "IX_organisation_org_id", unique: true
  end

  create_table "organisation_provider", id: :integer, force: :cascade do |t|
    t.integer "provider_id"
    t.integer "organisation_id"
    t.index ["organisation_id"], name: "IX_mc_organisation_provider_mc_organisation_id"
    t.index ["organisation_id"], name: "IX_organisation_provider_organisation_id"
    t.index ["provider_id"], name: "IX_mc_organisation_provider_provider_id"
    t.index ["provider_id"], name: "IX_organisation_provider_provider_id"
  end

  create_table "organisation_user", id: :integer, force: :cascade do |t|
    t.integer "organisation_id"
    t.integer "user_id"
    t.index ["organisation_id"], name: "IX_mc_organisation_user_mc_organisation_id"
    t.index ["organisation_id"], name: "IX_organisation_user_organisation_id"
    t.index ["user_id"], name: "IX_mc_organisation_user_mc_user_id"
    t.index ["user_id"], name: "IX_organisation_user_user_id"
  end

  create_table "pgde_course", id: :serial, force: :cascade do |t|
    t.text "course_code", null: false
    t.text "provider_code", null: false
  end

  create_table "provider", id: :integer, force: :cascade do |t|
    t.text "address4"
    t.text "provider_name"
    t.text "scheme_member"
    t.text "contact_name"
    t.text "year_code"
    t.text "provider_code"
    t.text "provider_type"
    t.text "postcode"
    t.integer "region_code"
    t.text "scitt"
    t.text "url"
    t.text "address1"
    t.text "address2"
    t.text "address3"
    t.text "email"
    t.text "telephone"
    t.string "accrediting_provider"
    t.index ["provider_code"], name: "IX_provider_provider_code", unique: true
    t.index ["provider_code"], name: "IX_ucas_provider_provider_code", unique: true
  end

  create_table "provider_enrichment", id: :integer, force: :cascade do |t|
    t.text "provider_code", null: false
    t.jsonb "json_data"
    t.integer "updated_by_user_id"
    t.datetime "created_timestamp_utc", default: "0001-01-01 00:00:00", null: false
    t.datetime "updated_timestamp_utc", default: "0001-01-01 00:00:00", null: false
    t.integer "created_by_user_id"
    t.datetime "last_published_timestamp_utc"
    t.integer "status", default: 0, null: false
    t.index ["created_by_user_id"], name: "IX_provider_enrichment_created_by_user_id"
    t.index ["provider_code"], name: "IX_provider_enrichment_provider_code"
    t.index ["updated_by_user_id"], name: "IX_provider_enrichment_updated_by_user_id"
  end

  create_table "session", id: :integer, force: :cascade do |t|
    t.text "access_token"
    t.datetime "created_utc", null: false
    t.integer "user_id", null: false
    t.index ["access_token", "created_utc"], name: "IX_mc_session_access_token_created_utc"
    t.index ["access_token", "created_utc"], name: "IX_session_access_token_created_utc"
    t.index ["user_id"], name: "IX_mc_session_mc_user_id"
    t.index ["user_id"], name: "IX_session_user_id"
  end

  create_table "site", id: :integer, force: :cascade do |t|
    t.text "address2"
    t.text "address3"
    t.text "address4"
    t.text "code", null: false
    t.text "location_name"
    t.text "postcode"
    t.text "address1"
    t.integer "provider_id", default: 0, null: false
    t.integer "region_code"
    t.index ["provider_id", "code"], name: "IX_site_provider_id_code", unique: true
  end

  create_table "subject", id: :integer, force: :cascade do |t|
    t.text "subject_name"
    t.text "subject_code", null: false
    t.index ["subject_code"], name: "AK_ucas_subject_subject_code", unique: true
    t.index ["subject_code"], name: "IX_subject_subject_code", unique: true
  end

  create_table "temp_tbl", id: false, force: :cascade do |t|
    t.text "code"
  end

  create_table "user", id: :integer, force: :cascade do |t|
    t.text "email"
    t.text "first_name"
    t.text "last_name"
    t.datetime "first_login_date_utc"
    t.datetime "last_login_date_utc"
    t.text "sign_in_user_id"
    t.datetime "welcome_email_date_utc"
    t.datetime "invite_date_utc"
    t.datetime "accept_terms_date_utc"
    t.index ["email"], name: "IX_mc_user_email", unique: true
    t.index ["email"], name: "IX_user_email", unique: true
  end

  add_foreign_key "access_request", "\"user\"", column: "requester_id", name: "FK_access_request_user_requester_id", on_delete: :nullify
  add_foreign_key "course", "provider", column: "accrediting_provider_id", name: "FK_course_provider_accrediting_provider_id"
  add_foreign_key "course", "provider", name: "FK_course_provider_provider_id", on_delete: :cascade
  add_foreign_key "course_enrichment", "\"user\"", column: "created_by_user_id", name: "FK_course_enrichment_user_created_by_user_id"
  add_foreign_key "course_enrichment", "\"user\"", column: "updated_by_user_id", name: "FK_course_enrichment_user_updated_by_user_id"
  add_foreign_key "course_site", "course", name: "FK_course_site_course_course_id", on_delete: :cascade
  add_foreign_key "course_site", "site", name: "FK_course_site_site_site_id", on_delete: :cascade
  add_foreign_key "course_subject", "course", name: "FK_course_subject_course_course_id", on_delete: :cascade
  add_foreign_key "course_subject", "subject", name: "FK_course_subject_subject_subject_id", on_delete: :cascade
  add_foreign_key "nctl_organisation", "organisation", name: "FK_nctl_organisation_organisation_organisation_id", on_delete: :cascade
  add_foreign_key "organisation_provider", "organisation", name: "FK_mc_organisation_provider_mc_organisation_mc_organisation_"
  add_foreign_key "organisation_provider", "organisation", name: "FK_organisation_provider_organisation_organisation_id"
  add_foreign_key "organisation_provider", "provider", name: "FK_mc_organisation_provider_provider_provider_id"
  add_foreign_key "organisation_provider", "provider", name: "FK_organisation_provider_provider_provider_id"
  add_foreign_key "organisation_user", "\"user\"", column: "user_id", name: "FK_mc_organisation_user_mc_user_mc_user_id"
  add_foreign_key "organisation_user", "\"user\"", column: "user_id", name: "FK_organisation_user_user_user_id"
  add_foreign_key "organisation_user", "organisation", name: "FK_mc_organisation_user_mc_organisation_mc_organisation_id"
  add_foreign_key "organisation_user", "organisation", name: "FK_organisation_user_organisation_organisation_id"
  add_foreign_key "provider_enrichment", "\"user\"", column: "created_by_user_id", name: "FK_provider_enrichment_user_created_by_user_id"
  add_foreign_key "provider_enrichment", "\"user\"", column: "updated_by_user_id", name: "FK_provider_enrichment_user_updated_by_user_id"
  add_foreign_key "session", "\"user\"", column: "user_id", name: "FK_mc_session_mc_user_mc_user_id", on_delete: :cascade
  add_foreign_key "session", "\"user\"", column: "user_id", name: "FK_session_user_user_id", on_delete: :cascade
  add_foreign_key "site", "provider", name: "FK_site_provider_provider_id", on_delete: :cascade
end
