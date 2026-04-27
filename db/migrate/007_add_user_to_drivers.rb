class AddUserToDrivers < ActiveRecord::Migration[8.0]
  def change
    add_reference :drivers, :user, null: true, foreign_key: false
    # add_index :drivers, :user_id
  end
end
