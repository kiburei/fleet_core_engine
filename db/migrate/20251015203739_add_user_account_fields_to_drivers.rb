class AddUserAccountFieldsToDrivers < ActiveRecord::Migration[8.0]
  def change
    add_column :drivers, :email, :string
    add_column :drivers, :create_user_account, :boolean, default: false
    
    add_index :drivers, :email, unique: true
  end
end
