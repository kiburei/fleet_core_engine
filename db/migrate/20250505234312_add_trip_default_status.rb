class AddTripDefaultStatus < ActiveRecord::Migration[8.0]
  def change
    change_column_default :trips, :status, from: nil, to: "scheduled"
    change_column_null :trips, :status, false
  end
end
