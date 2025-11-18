class CreateDevices < ActiveRecord::Migration[8.0]
  def change
    create_table :devices do |t|
      t.string :terminal_id
      t.references :vehicle, null: false, foreign_key: true
      t.datetime :last_heartbeat_at
      t.datetime :last_seen_at
      t.string :status

      t.timestamps
    end
    add_index :devices, :terminal_id
  end
end
