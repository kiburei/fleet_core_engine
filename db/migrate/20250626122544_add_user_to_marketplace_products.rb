class AddUserToMarketplaceProducts < ActiveRecord::Migration[8.0]
  def up
    # First add the column as nullable
    add_reference :marketplace_products, :user, null: true, foreign_key: true
    
    # Get the admin user to assign to existing products
    admin_user = User.find_by(email: 'admin@admin')
    
    if admin_user
      # Assign all existing products to the admin user
      Marketplace::Product.update_all(user_id: admin_user.id)
    else
      # If no admin user exists, create one
      admin_user = User.create!(
        first_name: 'Admin',
        last_name: 'User', 
        email: 'admin@admin',
        password: 'password',
        password_confirmation: 'password',
        phone_number: '0712345678'
      )
      admin_user.add_role(:admin)
      
      # Assign all existing products to this admin user
      Marketplace::Product.update_all(user_id: admin_user.id)
    end
    
    # Now make the column NOT NULL
    change_column_null :marketplace_products, :user_id, false
  end
  
  def down
    remove_reference :marketplace_products, :user, foreign_key: true
  end
end
