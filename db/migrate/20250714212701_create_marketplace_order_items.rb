class CreateMarketplaceOrderItems < ActiveRecord::Migration[8.0]
  def change
    create_table :marketplace_order_items do |t|
      t.references :order, null: false, foreign_key: { to_table: :marketplace_orders }
      t.references :product, null: false, foreign_key: { to_table: :marketplace_products }
      t.integer :quantity
      t.decimal :unit_price, precision: 10, scale: 2
      t.decimal :total_price, precision: 10, scale: 2

      t.timestamps
    end
  end
end
