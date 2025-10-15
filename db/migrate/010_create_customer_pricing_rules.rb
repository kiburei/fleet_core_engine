class CreateCustomerPricingRules < ActiveRecord::Migration[8.0]
  def change
    create_table :customer_pricing_rules do |t|
      t.references :customer, null: false, foreign_key: true
      
      # Rule details
      t.string :rule_name, null: false
      t.text :description
      
      # Distance-based pricing
      t.decimal :min_distance_km, precision: 8, scale: 2, default: 0.0
      t.decimal :max_distance_km, precision: 8, scale: 2
      
      # Time-based pricing (optional)
      t.time :start_time
      t.time :end_time
      t.json :applicable_days # ["monday", "tuesday", ...]
      
      # Order value-based pricing
      t.decimal :min_order_value, precision: 10, scale: 2
      t.decimal :max_order_value, precision: 10, scale: 2
      
      # Pricing structure
      t.integer :pricing_type, default: 0 # 0: flat_rate, 1: per_km, 2: tiered, 3: percentage
      t.decimal :base_rate, precision: 10, scale: 2
      t.decimal :per_km_rate, precision: 10, scale: 2, default: 0.0
      t.decimal :percentage_rate, precision: 5, scale: 2, default: 0.0 # For percentage-based pricing
      
      # Tiered pricing (JSON structure for complex pricing)
      t.json :tiered_rates # [{"min_km": 0, "max_km": 5, "rate": 10}, {"min_km": 5, "max_km": 10, "rate": 8}, ...]
      
      # Status and priority
      t.boolean :active, default: true
      t.integer :priority, default: 0 # Higher priority rules are applied first
      
      # Validity period
      t.datetime :valid_from
      t.datetime :valid_until
      
      # Usage tracking
      t.integer :usage_count, default: 0
      t.datetime :last_used_at
      
      t.timestamps
    end

    add_index :customer_pricing_rules, :active
    add_index :customer_pricing_rules, :priority
    add_index :customer_pricing_rules, [:valid_from, :valid_until]
    add_index :customer_pricing_rules, [:min_distance_km, :max_distance_km]
  end
end