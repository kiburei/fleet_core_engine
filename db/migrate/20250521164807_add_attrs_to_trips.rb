class AddAttrsToTrips < ActiveRecord::Migration[8.0]
  def change
    add_column :trips, :trackable, :boolean, default: false
    add_column :trips, :has_manifest, :boolean, default: false
  end
end
