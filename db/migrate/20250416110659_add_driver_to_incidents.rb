class AddDriverToIncidents < ActiveRecord::Migration[8.0]
  def change
    add_reference :incidents, :driver, null: false, foreign_key: true
  end
end
