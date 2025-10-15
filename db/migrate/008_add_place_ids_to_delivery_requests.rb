class AddPlaceIdsToDeliveryRequests < ActiveRecord::Migration[8.0]
  def change
    add_column :delivery_requests, :pickup_place_id, :string
    add_column :delivery_requests, :delivery_place_id, :string
    
    # Also allow coordinates to be nullable since we can geocode from address
    change_column :delivery_requests, :pickup_latitude, :decimal, precision: 10, scale: 6, null: true
    change_column :delivery_requests, :pickup_longitude, :decimal, precision: 10, scale: 6, null: true  
    change_column :delivery_requests, :delivery_latitude, :decimal, precision: 10, scale: 6, null: true
    change_column :delivery_requests, :delivery_longitude, :decimal, precision: 10, scale: 6, null: true
    
    # Add indexes for place_ids
    add_index :delivery_requests, :pickup_place_id
    add_index :delivery_requests, :delivery_place_id
  end
end