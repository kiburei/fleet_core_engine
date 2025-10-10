class AddDeliveryFieldsToDrivers < ActiveRecord::Migration[8.0]
  def change
    add_column :drivers, :is_available_for_delivery, :boolean, default: false
    add_column :drivers, :current_latitude, :decimal, precision: 10, scale: 6
    add_column :drivers, :current_longitude, :decimal, precision: 10, scale: 6
    add_column :drivers, :last_location_update, :timestamp
    # add_column :drivers, :phone_number, :string
    add_column :drivers, :fcm_token, :string  # For push notifications
    add_column :drivers, :delivery_rating, :decimal, precision: 3, scale: 2, default: 0.0
    add_column :drivers, :total_deliveries, :integer, default: 0
    add_column :drivers, :is_online, :boolean, default: false
    add_column :drivers, :max_delivery_distance_km, :integer, default: 50

    add_index :drivers, [ :current_latitude, :current_longitude ]
    add_index :drivers, :is_available_for_delivery
    add_index :drivers, :is_online
  end
end
