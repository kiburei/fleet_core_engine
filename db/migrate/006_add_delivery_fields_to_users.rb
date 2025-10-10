class AddDeliveryFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :phone, :string
    add_column :users, :fcm_token, :string
    # add_column :users, :first_name, :string
    # add_column :users, :last_name, :string

    add_index :users, :phone
    add_index :users, :fcm_token
  end
end
