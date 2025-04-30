class AddFleetProviderToMaintenance < ActiveRecord::Migration[8.0]
  def change
    add_reference :maintenances, :fleet_provider, null: false, foreign_key: true
  end
end
