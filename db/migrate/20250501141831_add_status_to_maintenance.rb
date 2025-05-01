class AddStatusToMaintenance < ActiveRecord::Migration[8.0]
  def change
    add_column :maintenances, :status, :string, default: 'pending'
  end
end
