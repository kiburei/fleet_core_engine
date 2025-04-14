class CreateFleetProviders < ActiveRecord::Migration[8.0]
  def change
    create_table :fleet_providers do |t|
      t.string :name
      t.string :registration_number
      t.string :physical_address
      t.string :phone_number
      t.string :email
      t.string :license_status
      t.date :license_expiry_date

      t.timestamps
    end
  end
end
