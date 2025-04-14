class CreateDrivers < ActiveRecord::Migration[8.0]
  def change
    create_table :drivers do |t|
      t.string :first_name
      t.string :middle_name
      t.string :last_name
      t.string :license_number
      t.string :phone_number
      t.references :vehicle, null: false, foreign_key: true
      t.references :fleet_provider, null: false, foreign_key: true

      t.timestamps
    end
  end
end
