class CreateMarketplaceOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :marketplace_orders do |t|
      t.references :user, null: false, foreign_key: true
      t.string :order_number
      t.decimal :total_amount, precision: 10, scale: 2
      t.integer :status, default: 0
      t.integer :payment_status, default: 0

      t.timestamps
    end
    add_index :marketplace_orders, :order_number
  end
end
