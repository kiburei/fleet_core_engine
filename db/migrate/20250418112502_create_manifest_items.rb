class CreateManifestItems < ActiveRecord::Migration[8.0]
  def change
    create_table :manifest_items do |t|
      t.references :manifest, null: false, foreign_key: true
      t.string :item_type
      t.string :description
      t.integer :quantity
      t.string :unit
      t.string :category

      t.timestamps
    end
  end
end
