class CreateLocationTrackings < ActiveRecord::Migration[8.0]
  def change
    create_table :location_trackings do |t|
      t.references :driver, null: false, foreign_key: true
      t.references :delivery_request, null: true, foreign_key: true
      
      t.decimal :latitude, precision: 10, scale: 6, null: false
      t.decimal :longitude, precision: 10, scale: 6, null: false
      t.decimal :accuracy, precision: 8, scale: 2  # GPS accuracy in meters
      t.decimal :speed, precision: 8, scale: 2  # Speed in km/h
      t.decimal :bearing, precision: 8, scale: 2  # Direction in degrees
      t.datetime :recorded_at, null: false
      
      t.timestamps
    end

    add_index :location_trackings, [:driver_id, :recorded_at]
    add_index :location_trackings, [:delivery_request_id, :recorded_at]
    add_index :location_trackings, [:latitude, :longitude]
    add_index :location_trackings, :recorded_at
  end
end