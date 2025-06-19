class CreateMarketplaceProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :marketplace_products do |t|
      t.string :name
      t.text :description
      t.decimal :price
      t.string :category
      t.string :target_audience
      t.boolean :active
      t.boolean :featured
      t.string :tags

      t.timestamps
    end
  end
end
