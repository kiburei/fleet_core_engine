class CreateIncidents < ActiveRecord::Migration[8.0]
  def change
    create_table :incidents do |t|
      t.references :vehicle, null: false, foreign_key: true
      t.date :incident_date
      t.string :description

      t.timestamps
    end
  end
end
