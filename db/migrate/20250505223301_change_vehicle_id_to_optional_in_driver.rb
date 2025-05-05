class ChangeVehicleIdToOptionalInDriver < ActiveRecord::Migration[8.0]
  def change
    change_column_null :drivers, :vehicle_id, true
    change_column_default :drivers, :vehicle_id, nil
  end
end
