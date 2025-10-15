class UpdateDeliveryRequestsForCustomers < ActiveRecord::Migration[8.0]
  def change
    # Rename customer reference to business_customer
    rename_column :delivery_requests, :customer_id, :business_customer_id
    
    # Add end customer (recipient) information
    add_column :delivery_requests, :end_customer_name, :string
    add_column :delivery_requests, :end_customer_phone, :string
    add_column :delivery_requests, :end_customer_email, :string
    
    # Add order information
    add_column :delivery_requests, :order_value, :decimal, precision: 10, scale: 2
    add_column :delivery_requests, :order_items_count, :integer, default: 1
    add_column :delivery_requests, :special_instructions, :text
    
    # Payment split information
    add_column :delivery_requests, :business_payment_amount, :decimal, precision: 10, scale: 2, default: 0.0
    add_column :delivery_requests, :customer_payment_amount, :decimal, precision: 10, scale: 2, default: 0.0
    add_column :delivery_requests, :payment_method, :string # cash, card, split, etc.
    
    # Update foreign key
    remove_foreign_key :delivery_requests, :users
    add_foreign_key :delivery_requests, :customers, column: :business_customer_id
    
    # Add indexes
    add_index :delivery_requests, :end_customer_phone
    add_index :delivery_requests, :order_value
    add_index :delivery_requests, :payment_method
  end
end