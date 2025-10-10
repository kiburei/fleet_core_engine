class AddDeliveryFieldsToFleetProviders < ActiveRecord::Migration[8.0]
  def change
    add_column :fleet_providers, :is_delivery_enabled, :boolean, default: false
    add_column :fleet_providers, :delivery_commission_rate, :decimal, precision: 5, scale: 4, default: 0.15
    add_column :fleet_providers, :delivery_radius_km, :integer, default: 50
    add_column :fleet_providers, :min_delivery_fee, :decimal, precision: 8, scale: 2, default: 5.0
    add_column :fleet_providers, :max_delivery_fee, :decimal, precision: 8, scale: 2, default: 100.0
    add_column :fleet_providers, :delivery_per_km_rate, :decimal, precision: 6, scale: 2, default: 2.0

    add_index :fleet_providers, :is_delivery_enabled
  end
end