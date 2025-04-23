class AddAttrToMaintenance < ActiveRecord::Migration[8.0]
  def change
    add_column :maintenances, :maintenance_type, :string
    add_column :maintenances, :service_provider, :string
    add_column :maintenances, :odometer, :integer
    add_column :maintenances, :next_service_due, :date
  end
end
