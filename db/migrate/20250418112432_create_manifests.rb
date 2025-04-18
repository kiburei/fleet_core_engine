class CreateManifests < ActiveRecord::Migration[8.0]
  def change
    create_table :manifests do |t|
      t.references :trip, null: false, foreign_key: true
      t.text :notes

      t.timestamps
    end
  end
end
