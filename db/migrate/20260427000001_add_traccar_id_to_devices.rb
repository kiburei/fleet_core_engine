class AddTraccarIdToDevices < ActiveRecord::Migration[8.0]
  def change
    add_column :devices, :traccar_id, :integer
    add_index :devices, :traccar_id, unique: true
  end
end
