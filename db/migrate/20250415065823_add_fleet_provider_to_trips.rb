class AddFleetProviderToTrips < ActiveRecord::Migration[8.0]
  def change
    add_reference :trips, :fleet_provider, null: false, foreign_key: true
  end
end
