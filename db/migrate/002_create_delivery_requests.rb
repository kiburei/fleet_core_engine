class CreateDeliveryRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :delivery_requests do |t|
      t.references :marketplace_order, null: false, foreign_key: { to_table: :marketplace_orders }
      t.references :customer, null: false, foreign_key: { to_table: :users }
      t.references :driver, null: true, foreign_key: true
      t.references :fleet_provider, null: false, foreign_key: true
      
      # Pickup location
      t.string :pickup_address, null: false
      t.decimal :pickup_latitude, precision: 10, scale: 6, null: false
      t.decimal :pickup_longitude, precision: 10, scale: 6, null: false
      t.text :pickup_instructions
      t.string :pickup_contact_name
      t.string :pickup_contact_phone
      
      # Delivery location
      t.string :delivery_address, null: false
      t.decimal :delivery_latitude, precision: 10, scale: 6, null: false
      t.decimal :delivery_longitude, precision: 10, scale: 6, null: false
      t.text :delivery_instructions
      t.string :delivery_contact_name
      t.string :delivery_contact_phone
      
      # Request details
      t.string :request_number, null: false, index: { unique: true }
      t.integer :priority, default: 0  # 0: normal, 1: high, 2: urgent
      t.decimal :estimated_distance_km, precision: 8, scale: 2
      t.integer :estimated_duration_minutes
      t.decimal :delivery_fee, precision: 10, scale: 2, null: false
      
      # Status and timing
      t.integer :status, default: 0, null: false
      t.datetime :requested_at, null: false
      t.datetime :assigned_at
      t.datetime :picked_up_at
      t.datetime :delivered_at
      t.datetime :cancelled_at
      t.text :cancellation_reason
      
      # Payment
      t.integer :payment_status, default: 0, null: false
      t.decimal :driver_commission, precision: 10, scale: 2
      t.decimal :platform_fee, precision: 10, scale: 2
      
      t.timestamps
    end

    add_index :delivery_requests, :status
    add_index :delivery_requests, [:pickup_latitude, :pickup_longitude]
    add_index :delivery_requests, [:delivery_latitude, :delivery_longitude]
    add_index :delivery_requests, :requested_at
    add_index :delivery_requests, :priority
  end
end