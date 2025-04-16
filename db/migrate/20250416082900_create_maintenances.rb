class CreateMaintenances < ActiveRecord::Migration[8.0]
  def change
    create_table :maintenances do |t|
      t.references :vehicle, null: false, foreign_key: true
      t.date :maintenance_date
      t.string :description
      t.decimal :maintenance_cost

      t.timestamps
    end
  end
end
