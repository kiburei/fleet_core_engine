class CreateCustomers < ActiveRecord::Migration[8.0]
  def change
    create_table :customers do |t|
      # Business Information
      t.string :business_name, null: false
      t.string :business_type # restaurant, warehouse, retail, pharmacy, etc.
      t.string :business_registration_number
      t.text :business_description
      
      # Contact Information
      t.string :primary_contact_name, null: false
      t.string :primary_contact_phone, null: false
      t.string :primary_contact_email, null: false
      t.string :secondary_contact_name
      t.string :secondary_contact_phone
      t.string :secondary_contact_email
      
      # Address Information
      t.text :business_address, null: false
      t.decimal :business_latitude, precision: 10, scale: 6
      t.decimal :business_longitude, precision: 10, scale: 6
      t.string :business_place_id
      t.string :city
      t.string :state
      t.string :country
      t.string :postal_code
      
      # Business Hours
      t.json :operating_hours # Store as JSON: {"monday": {"open": "09:00", "close": "18:00"}, ...}
      t.string :timezone, default: 'UTC'
      
      # Payment & Billing
      t.string :payment_terms # net_30, net_15, immediate, etc.
      t.string :billing_contact_name
      t.string :billing_contact_email
      t.string :billing_contact_phone
      t.text :billing_address
      t.string :tax_id_number
      
      # Payment Method Preferences
      t.integer :default_payment_method, default: 0 # 0: customer_pays, 1: business_pays, 2: split_payment
      t.decimal :business_payment_percentage, precision: 5, scale: 2, default: 0.0 # For split payments
      
      # Pricing
      t.decimal :base_delivery_rate, precision: 10, scale: 2
      t.decimal :per_km_rate, precision: 10, scale: 2
      t.decimal :minimum_order_value, precision: 10, scale: 2, default: 0.0
      t.decimal :free_delivery_threshold, precision: 10, scale: 2 # Free delivery above this amount
      
      # Service Settings
      t.integer :max_delivery_radius_km, default: 50
      t.integer :estimated_prep_time_minutes, default: 30
      t.boolean :allows_cash_on_delivery, default: true
      t.boolean :allows_card_on_delivery, default: false
      t.boolean :requires_signature, default: false
      t.boolean :allows_contactless_delivery, default: true
      
      # Status & Tracking
      t.integer :status, default: 0 # 0: pending_approval, 1: active, 2: inactive, 3: suspended
      t.text :status_notes
      t.datetime :activated_at
      t.datetime :suspended_at
      
      # Relationships
      t.references :fleet_provider, null: false, foreign_key: true
      t.references :account_manager, null: true, foreign_key: { to_table: :users } # Staff member managing this account
      
      # Agreement & Legal
      t.datetime :agreement_signed_at
      t.string :agreement_version
      t.text :special_terms # Special clauses or notes
      
      # Analytics
      t.integer :total_deliveries_count, default: 0
      t.decimal :total_revenue, precision: 15, scale: 2, default: 0.0
      t.decimal :average_order_value, precision: 10, scale: 2, default: 0.0
      t.decimal :customer_rating, precision: 3, scale: 2 # Average rating from drivers
      
      t.timestamps
    end

    # Indexes for common queries
    add_index :customers, :business_name
    add_index :customers, :business_type
    add_index :customers, :status
    add_index :customers, [:business_latitude, :business_longitude]
    add_index :customers, :primary_contact_email, unique: true
    add_index :customers, :created_at
    add_index :customers, :total_deliveries_count
    add_index :customers, :customer_rating
  end
end