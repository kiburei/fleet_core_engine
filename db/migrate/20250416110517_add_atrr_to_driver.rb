class AddAtrrToDriver < ActiveRecord::Migration[8.0]
  def change
    add_column :drivers, :blood_group, :string
    add_column :drivers, :license_expiry_date, :date
    add_column :drivers, :license_status, :string
  end
end
