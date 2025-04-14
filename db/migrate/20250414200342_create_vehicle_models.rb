class CreateVehicleModels < ActiveRecord::Migration[8.0]
  def change
    create_table :vehicle_models do |t|
      t.string :make
      t.string :model
      t.string :category
      t.integer :year
      t.string :fuel_type
      t.string :transmission
      t.string :body_type
      t.integer :capacity

      t.timestamps
    end
  end
end
