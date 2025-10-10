class AddUserToDrivers < ActiveRecord::Migration[8.0]
  def change
    add_reference :drivers, :user, null: true, foreign_key: true
    # add_index :drivers, :user_id
  end
end
