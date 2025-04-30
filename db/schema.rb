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

ActiveRecord::Schema[8.0].define(version: 2025_04_30_210047) do
  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "activities", force: :cascade do |t|
    t.integer "vehicle_id", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["vehicle_id"], name: "index_activities_on_vehicle_id"
  end

  create_table "documents", force: :cascade do |t|
    t.string "title"
    t.string "document_type"
    t.date "issue_date"
    t.date "expiry_date"
    t.string "documentable_type", null: false
    t.integer "documentable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["documentable_type", "documentable_id"], name: "index_documents_on_documentable"
  end

  create_table "drivers", force: :cascade do |t|
    t.string "first_name"
    t.string "middle_name"
    t.string "last_name"
    t.string "license_number"
    t.string "phone_number"
    t.integer "vehicle_id", null: false
    t.integer "fleet_provider_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "blood_group"
    t.date "license_expiry_date"
    t.string "license_status"
    t.index ["fleet_provider_id"], name: "index_drivers_on_fleet_provider_id"
    t.index ["vehicle_id"], name: "index_drivers_on_vehicle_id"
  end

  create_table "fleet_providers", force: :cascade do |t|
    t.string "name"
    t.string "registration_number"
    t.string "physical_address"
    t.string "phone_number"
    t.string "email"
    t.string "license_status"
    t.date "license_expiry_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "incidents", force: :cascade do |t|
    t.integer "vehicle_id", null: false
    t.date "incident_date"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "driver_id", null: false
    t.string "incident_type"
    t.decimal "damage_cost", precision: 10, scale: 2
    t.string "location"
    t.string "report_reference"
    t.integer "fleet_provider_id", null: false
    t.index ["driver_id"], name: "index_incidents_on_driver_id"
    t.index ["fleet_provider_id"], name: "index_incidents_on_fleet_provider_id"
    t.index ["vehicle_id"], name: "index_incidents_on_vehicle_id"
  end

  create_table "maintenances", force: :cascade do |t|
    t.integer "vehicle_id", null: false
    t.date "maintenance_date"
    t.string "description"
    t.decimal "maintenance_cost"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "maintenance_type"
    t.string "service_provider"
    t.integer "odometer"
    t.date "next_service_due"
    t.integer "fleet_provider_id", null: false
    t.index ["fleet_provider_id"], name: "index_maintenances_on_fleet_provider_id"
    t.index ["vehicle_id"], name: "index_maintenances_on_vehicle_id"
  end

  create_table "manifest_items", force: :cascade do |t|
    t.integer "manifest_id", null: false
    t.string "item_type"
    t.string "description"
    t.integer "quantity"
    t.string "unit"
    t.string "category"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["manifest_id"], name: "index_manifest_items_on_manifest_id"
  end

  create_table "manifests", force: :cascade do |t|
    t.integer "trip_id", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["trip_id"], name: "index_manifests_on_trip_id"
  end

  create_table "roles", force: :cascade do |t|
    t.string "name"
    t.string "resource_type"
    t.integer "resource_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id"
    t.index ["name"], name: "index_roles_on_name"
    t.index ["resource_type", "resource_id"], name: "index_roles_on_resource"
  end

  create_table "trips", force: :cascade do |t|
    t.integer "vehicle_id", null: false
    t.integer "driver_id", null: false
    t.string "origin"
    t.string "destination"
    t.datetime "departure_time"
    t.datetime "arrival_time"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "fleet_provider_id", null: false
    t.index ["driver_id"], name: "index_trips_on_driver_id"
    t.index ["fleet_provider_id"], name: "index_trips_on_fleet_provider_id"
    t.index ["vehicle_id"], name: "index_trips_on_vehicle_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "fleet_provider_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["fleet_provider_id"], name: "index_users_on_fleet_provider_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "users_roles", id: false, force: :cascade do |t|
    t.integer "user_id"
    t.integer "role_id"
    t.index ["role_id"], name: "index_users_roles_on_role_id"
    t.index ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id"
    t.index ["user_id"], name: "index_users_roles_on_user_id"
  end

  create_table "vehicle_models", force: :cascade do |t|
    t.string "make"
    t.string "model"
    t.string "category"
    t.integer "year"
    t.string "fuel_type"
    t.string "transmission"
    t.string "body_type"
    t.integer "capacity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "vehicles", force: :cascade do |t|
    t.integer "vehicle_model_id", null: false
    t.string "registration_number"
    t.string "status"
    t.integer "fleet_provider_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["fleet_provider_id"], name: "index_vehicles_on_fleet_provider_id"
    t.index ["vehicle_model_id"], name: "index_vehicles_on_vehicle_model_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "activities", "vehicles"
  add_foreign_key "drivers", "fleet_providers"
  add_foreign_key "drivers", "vehicles"
  add_foreign_key "incidents", "drivers"
  add_foreign_key "incidents", "fleet_providers"
  add_foreign_key "incidents", "vehicles"
  add_foreign_key "maintenances", "fleet_providers"
  add_foreign_key "maintenances", "vehicles"
  add_foreign_key "manifest_items", "manifests"
  add_foreign_key "manifests", "trips"
  add_foreign_key "trips", "drivers"
  add_foreign_key "trips", "fleet_providers"
  add_foreign_key "trips", "vehicles"
  add_foreign_key "users", "fleet_providers"
  add_foreign_key "vehicles", "fleet_providers"
  add_foreign_key "vehicles", "vehicle_models"
end
