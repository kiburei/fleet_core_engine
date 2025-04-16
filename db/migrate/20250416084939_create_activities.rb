class CreateActivities < ActiveRecord::Migration[8.0]
  def change
    create_table :activities do |t|
      t.references :vehicle, null: false, foreign_key: true
      t.text :description

      t.timestamps
    end
  end
end
