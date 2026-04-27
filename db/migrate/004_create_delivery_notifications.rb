class CreateDeliveryNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :delivery_notifications do |t|
      t.references :delivery_request, null: false, foreign_key: false
      t.references :recipient, null: false, foreign_key: false
      
      t.string :notification_type, null: false  # 'order_assigned', 'picked_up', 'delivered', etc.
      t.string :title, null: false
      t.text :message, null: false
      t.json :metadata  # Additional data for the notification
      
      t.boolean :read, default: false
      t.boolean :push_sent, default: false
      t.datetime :sent_at
      
      t.timestamps
    end

    add_index :delivery_notifications, [:recipient_id, :read]
    add_index :delivery_notifications, :notification_type
    add_index :delivery_notifications, :sent_at
  end
end