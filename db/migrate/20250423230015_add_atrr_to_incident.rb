class AddAtrrToIncident < ActiveRecord::Migration[8.0]
  def change
    add_column :incidents, :incident_type, :string
    add_column :incidents, :damage_cost, :decimal, precision: 10, scale: 2
    add_column :incidents, :location, :string
    add_column :incidents, :report_reference, :string
  end
end
