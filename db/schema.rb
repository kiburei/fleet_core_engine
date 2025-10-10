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

ActiveRecord::Schema[8.0].define(version: 2025_10_09_173741) do
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

  create_table "delivery_notifications", force: :cascade do |t|
    t.integer "delivery_request_id", null: false
    t.integer "recipient_id", null: false
    t.string "notification_type", null: false
    t.string "title", null: false
    t.text "message", null: false
    t.json "metadata"
    t.boolean "read", default: false
    t.boolean "push_sent", default: false
    t.datetime "sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["delivery_request_id"], name: "index_delivery_notifications_on_delivery_request_id"
    t.index ["notification_type"], name: "index_delivery_notifications_on_notification_type"
    t.index ["recipient_id", "read"], name: "index_delivery_notifications_on_recipient_id_and_read"
    t.index ["recipient_id"], name: "index_delivery_notifications_on_recipient_id"
    t.index ["sent_at"], name: "index_delivery_notifications_on_sent_at"
  end

  create_table "delivery_requests", force: :cascade do |t|
    t.integer "marketplace_order_id", null: false
    t.integer "customer_id", null: false
    t.integer "driver_id"
    t.integer "fleet_provider_id", null: false
    t.string "pickup_address", null: false
    t.decimal "pickup_latitude", precision: 10, scale: 6, null: false
    t.decimal "pickup_longitude", precision: 10, scale: 6, null: false
    t.text "pickup_instructions"
    t.string "pickup_contact_name"
    t.string "pickup_contact_phone"
    t.string "delivery_address", null: false
    t.decimal "delivery_latitude", precision: 10, scale: 6, null: false
    t.decimal "delivery_longitude", precision: 10, scale: 6, null: false
    t.text "delivery_instructions"
    t.string "delivery_contact_name"
    t.string "delivery_contact_phone"
    t.string "request_number", null: false
    t.integer "priority", default: 0
    t.decimal "estimated_distance_km", precision: 8, scale: 2
    t.integer "estimated_duration_minutes"
    t.decimal "delivery_fee", precision: 10, scale: 2, null: false
    t.integer "status", default: 0, null: false
    t.datetime "requested_at", null: false
    t.datetime "assigned_at"
    t.datetime "picked_up_at"
    t.datetime "delivered_at"
    t.datetime "cancelled_at"
    t.text "cancellation_reason"
    t.integer "payment_status", default: 0, null: false
    t.decimal "driver_commission", precision: 10, scale: 2
    t.decimal "platform_fee", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_delivery_requests_on_customer_id"
    t.index ["delivery_latitude", "delivery_longitude"], name: "idx_on_delivery_latitude_delivery_longitude_a9efd74e32"
    t.index ["driver_id"], name: "index_delivery_requests_on_driver_id"
    t.index ["fleet_provider_id"], name: "index_delivery_requests_on_fleet_provider_id"
    t.index ["marketplace_order_id"], name: "index_delivery_requests_on_marketplace_order_id"
    t.index ["pickup_latitude", "pickup_longitude"], name: "idx_on_pickup_latitude_pickup_longitude_3a838c05f0"
    t.index ["priority"], name: "index_delivery_requests_on_priority"
    t.index ["request_number"], name: "index_delivery_requests_on_request_number", unique: true
    t.index ["requested_at"], name: "index_delivery_requests_on_requested_at"
    t.index ["status"], name: "index_delivery_requests_on_status"
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
    t.integer "vehicle_id"
    t.integer "fleet_provider_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "blood_group"
    t.date "license_expiry_date"
    t.string "license_status"
    t.boolean "is_available_for_delivery", default: false
    t.decimal "current_latitude", precision: 10, scale: 6
    t.decimal "current_longitude", precision: 10, scale: 6
    t.datetime "last_location_update"
    t.string "fcm_token"
    t.decimal "delivery_rating", precision: 3, scale: 2, default: "0.0"
    t.integer "total_deliveries", default: 0
    t.boolean "is_online", default: false
    t.integer "max_delivery_distance_km", default: 50
    t.integer "user_id"
    t.string "status", default: "offline"
    t.index ["current_latitude", "current_longitude"], name: "index_drivers_on_current_latitude_and_current_longitude"
    t.index ["fleet_provider_id"], name: "index_drivers_on_fleet_provider_id"
    t.index ["is_available_for_delivery"], name: "index_drivers_on_is_available_for_delivery"
    t.index ["is_online"], name: "index_drivers_on_is_online"
    t.index ["status"], name: "index_drivers_on_status"
    t.index ["user_id"], name: "index_drivers_on_user_id"
    t.index ["vehicle_id"], name: "index_drivers_on_vehicle_id"
  end

  create_table "fleet_provider_users", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "fleet_provider_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["fleet_provider_id"], name: "index_fleet_provider_users_on_fleet_provider_id"
    t.index ["user_id"], name: "index_fleet_provider_users_on_user_id"
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
    t.boolean "is_delivery_enabled", default: false
    t.decimal "delivery_commission_rate", precision: 5, scale: 4, default: "0.15"
    t.integer "delivery_radius_km", default: 50
    t.decimal "min_delivery_fee", precision: 8, scale: 2, default: "5.0"
    t.decimal "max_delivery_fee", precision: 8, scale: 2, default: "100.0"
    t.decimal "delivery_per_km_rate", precision: 6, scale: 2, default: "2.0"
    t.index ["is_delivery_enabled"], name: "index_fleet_providers_on_is_delivery_enabled"
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

  create_table "location_trackings", force: :cascade do |t|
    t.integer "driver_id", null: false
    t.integer "delivery_request_id"
    t.decimal "latitude", precision: 10, scale: 6, null: false
    t.decimal "longitude", precision: 10, scale: 6, null: false
    t.decimal "accuracy", precision: 8, scale: 2
    t.decimal "speed", precision: 8, scale: 2
    t.decimal "bearing", precision: 8, scale: 2
    t.datetime "recorded_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["delivery_request_id", "recorded_at"], name: "idx_on_delivery_request_id_recorded_at_0b61e363c8"
    t.index ["delivery_request_id"], name: "index_location_trackings_on_delivery_request_id"
    t.index ["driver_id", "recorded_at"], name: "index_location_trackings_on_driver_id_and_recorded_at"
    t.index ["driver_id"], name: "index_location_trackings_on_driver_id"
    t.index ["latitude", "longitude"], name: "index_location_trackings_on_latitude_and_longitude"
    t.index ["recorded_at"], name: "index_location_trackings_on_recorded_at"
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
    t.string "status", default: "pending"
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

  create_table "marketplace_order_items", force: :cascade do |t|
    t.integer "order_id", null: false
    t.integer "product_id", null: false
    t.integer "quantity"
    t.decimal "unit_price", precision: 10, scale: 2
    t.decimal "total_price", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_marketplace_order_items_on_order_id"
    t.index ["product_id"], name: "index_marketplace_order_items_on_product_id"
  end

  create_table "marketplace_orders", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "order_number"
    t.decimal "total_amount", precision: 10, scale: 2
    t.integer "status", default: 0
    t.integer "payment_status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_number"], name: "index_marketplace_orders_on_order_number"
    t.index ["user_id"], name: "index_marketplace_orders_on_user_id"
  end

  create_table "marketplace_payments", force: :cascade do |t|
    t.integer "order_id", null: false
    t.integer "user_id", null: false
    t.decimal "amount", precision: 10, scale: 2
    t.integer "payment_method", default: 0
    t.integer "status", default: 0
    t.string "transaction_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_marketplace_payments_on_order_id"
    t.index ["transaction_id"], name: "index_marketplace_payments_on_transaction_id"
    t.index ["user_id"], name: "index_marketplace_payments_on_user_id"
  end

  create_table "marketplace_products", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.decimal "price"
    t.string "category"
    t.string "target_audience"
    t.boolean "active"
    t.boolean "featured"
    t.string "tags"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_marketplace_products_on_user_id"
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
    t.string "status", default: "scheduled", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "fleet_provider_id", null: false
    t.boolean "trackable", default: false
    t.boolean "has_manifest", default: false
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
    t.string "first_name"
    t.string "last_name"
    t.string "other_name"
    t.string "phone_number"
    t.string "phone"
    t.string "fcm_token"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["fcm_token"], name: "index_users_on_fcm_token"
    t.index ["fleet_provider_id"], name: "index_users_on_fleet_provider_id"
    t.index ["phone"], name: "index_users_on_phone"
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
  add_foreign_key "delivery_notifications", "delivery_requests"
  add_foreign_key "delivery_notifications", "users", column: "recipient_id"
  add_foreign_key "delivery_requests", "drivers"
  add_foreign_key "delivery_requests", "fleet_providers"
  add_foreign_key "delivery_requests", "marketplace_orders"
  add_foreign_key "delivery_requests", "users", column: "customer_id"
  add_foreign_key "drivers", "fleet_providers"
  add_foreign_key "drivers", "users"
  add_foreign_key "drivers", "vehicles"
  add_foreign_key "fleet_provider_users", "fleet_providers"
  add_foreign_key "fleet_provider_users", "users"
  add_foreign_key "incidents", "drivers"
  add_foreign_key "incidents", "fleet_providers"
  add_foreign_key "incidents", "vehicles"
  add_foreign_key "location_trackings", "delivery_requests"
  add_foreign_key "location_trackings", "drivers"
  add_foreign_key "maintenances", "fleet_providers"
  add_foreign_key "maintenances", "vehicles"
  add_foreign_key "manifest_items", "manifests"
  add_foreign_key "manifests", "trips"
  add_foreign_key "marketplace_order_items", "marketplace_orders", column: "order_id"
  add_foreign_key "marketplace_order_items", "marketplace_products", column: "product_id"
  add_foreign_key "marketplace_orders", "users"
  add_foreign_key "marketplace_payments", "marketplace_orders", column: "order_id"
  add_foreign_key "marketplace_payments", "users"
  add_foreign_key "marketplace_products", "users"
  add_foreign_key "trips", "drivers"
  add_foreign_key "trips", "fleet_providers"
  add_foreign_key "trips", "vehicles"
  add_foreign_key "users", "fleet_providers"
  add_foreign_key "vehicles", "fleet_providers"
  add_foreign_key "vehicles", "vehicle_models"
end
