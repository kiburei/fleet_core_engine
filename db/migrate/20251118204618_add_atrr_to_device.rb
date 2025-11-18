class AddAtrrToDevice < ActiveRecord::Migration[8.0]
  def change
    add_column :devices, :sim_number, :string
    add_column :devices, :name, :string
  end
end
