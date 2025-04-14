class CreateTrips < ActiveRecord::Migration[8.0]
  def change
    create_table :trips do |t|
      t.references :vehicle, null: false, foreign_key: true
      t.references :driver, null: false, foreign_key: true
      t.string :origin
      t.string :destination
      t.datetime :departure_time
      t.datetime :arrival_time
      t.string :status

      t.timestamps
    end
  end
end
