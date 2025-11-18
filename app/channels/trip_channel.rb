class TripChannel < ApplicationCable::Channel
  def subscribed
    stream_from "trip_#{params[:trip_id]}"
  end
end
