class CreateGpsPoints < ActiveRecord::Migration[8.0]
  def change
    create_table :gps_points do |t|
      t.references :vehicle, null: false, foreign_key: true
      t.references :trip, null: false, foreign_key: true
      t.float :latitude
      t.float :longitude
      t.float :speed
      t.float :heading
      t.datetime :timestamp
      t.text :raw_payload

      t.timestamps
    end
  end
end
