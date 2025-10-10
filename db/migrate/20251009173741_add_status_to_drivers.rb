class AddStatusToDrivers < ActiveRecord::Migration[7.1]
  def change
    add_column :drivers, :status, :string, default: 'offline'
    add_index :drivers, :status
    
    # Update existing records to set status based on current boolean fields
    reversible do |dir|
      dir.up do
        # Set status based on existing boolean fields
        execute <<-SQL
          UPDATE drivers 
          SET status = CASE 
            WHEN is_online = true AND is_available_for_delivery = true THEN 'available'
            WHEN is_online = true AND is_available_for_delivery = false THEN 'busy'
            ELSE 'offline'
          END
        SQL
      end
    end
  end
end
