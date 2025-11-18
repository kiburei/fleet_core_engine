class VehicleChannel < ApplicationCable::Channel
  def subscribed
    stream_from "vehicle_#{params[:vehicle_id]}"
  end
end
