class AddFleetProviderIdToUsers < ActiveRecord::Migration[8.0]
  def change
    add_reference :users, :fleet_provider, foreign_key: true
  end
end
