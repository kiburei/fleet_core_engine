class CreateVehicles < ActiveRecord::Migration[8.0]
  def change
    create_table :vehicles do |t|
      t.references :vehicle_model, null: false, foreign_key: true
      t.string :registration_number
      t.string :status
      t.references :fleet_provider, null: false, foreign_key: true

      t.timestamps
    end
  end
end
