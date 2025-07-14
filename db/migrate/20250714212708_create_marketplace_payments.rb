class CreateMarketplacePayments < ActiveRecord::Migration[8.0]
  def change
    create_table :marketplace_payments do |t|
      t.references :order, null: false, foreign_key: { to_table: :marketplace_orders }
      t.references :user, null: false, foreign_key: true
      t.decimal :amount, precision: 10, scale: 2
      t.integer :payment_method, default: 0
      t.integer :status, default: 0
      t.string :transaction_id

      t.timestamps
    end
    add_index :marketplace_payments, :transaction_id
  end
end
