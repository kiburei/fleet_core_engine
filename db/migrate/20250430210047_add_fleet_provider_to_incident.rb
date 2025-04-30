class AddFleetProviderToIncident < ActiveRecord::Migration[8.0]
  def change
    add_reference :incidents, :fleet_provider, null: false, foreign_key: true
  end
end
