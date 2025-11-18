module Jt808
  class Processor
    #
    # MAIN DISPATCHER
    #
    def self.process(packet, socket)
      case packet[:message_id]
      when 0x0002 # heartbeat
        handle_heartbeat(packet, socket)
      when 0x0200 # location report
        handle_location(packet, socket)
      else
        Rails.logger.info "Unhandled 808 packet: #{packet[:message_id].to_s(16)}"
      end
    end

    # ---------------------------------------------------------------------
    # HEARTBEAT (0x0002)
    # ---------------------------------------------------------------------
    def self.handle_heartbeat(pkt, socket)
      device = Device.find_by(terminal_id: pkt[:phone])

      unless device
        Rails.logger.warn "Heartbeat from unknown device #{pkt[:phone]}"
        return
      end

      # Automatic linking already happens because each device belongs_to :vehicle
      device.update!(
        last_heartbeat_at: Time.current,
        status: "online"
      )

      # Send ACK (0x8001)
      socket.write Response.general_response(pkt)
    end



    # ---------------------------------------------------------------------
    # LOCATION REPORT (0x0200)
    # ---------------------------------------------------------------------
    def self.handle_location(pkt, socket)
      device = Device.find_by(terminal_id: pkt[:phone])

      unless device
        Rails.logger.warn "Location report from unknown device #{pkt[:phone]}"
        return
      end

      #
      # ---- Automatic Tracking → Vehicle ↔ Device ----
      #
      # This is already automatic via:
      # device belongs_to :vehicle
      # So device.vehicle gives us the assigned vehicle
      #

      unless device.vehicle
        Rails.logger.warn "Device #{device.terminal_id} has no assigned vehicle — location ignored."
        return
      end

      location = Jt808::Decoders.decode_location(pkt[:body_hex])

      # Save GPS point
      point = GpsPoint.create!(
        vehicle: device.vehicle,
        trip: device.vehicle.current_trip,    # auto-linked to active trip
        latitude:  location[:lat],
        longitude: location[:lng],
        speed:     location[:speed],
        heading:   location[:direction],
        timestamp: location[:timestamp],
        raw_payload: pkt[:body_hex]
      )

      #
      # 1️⃣ Send live GPS to vehicle page
      #
      broadcast_vehicle_position(device.vehicle, location)

      #
      # 2️⃣ Send live GPS to trip page (if a trip is active)
      #
      if device.vehicle.current_trip.present?
        broadcast_trip_position(device.vehicle.current_trip, location)
      end

      # Send ACK
      socket.write Response.general_response(pkt)
    end



    # ---------------------------------------------------------------------
    # VEHICLE LIVE POSITION BROADCAST
    # ---------------------------------------------------------------------
    def self.broadcast_vehicle_position(vehicle, loc)
      ActionCable.server.broadcast(
        "vehicle_#{vehicle.id}",
        {
          lat:      loc[:lat],
          lng:      loc[:lng],
          speed:    loc[:speed],
          heading:  loc[:direction],
          timestamp: loc[:timestamp].strftime("%F %T")
        }
      )
    end



    # ---------------------------------------------------------------------
    # TRIP LIVE POSITION BROADCAST
    # ---------------------------------------------------------------------
    def self.broadcast_trip_position(trip, loc)
      ActionCable.server.broadcast(
        "trip_#{trip.id}",
        {
          lat:      loc[:lat],
          lng:      loc[:lng],
          speed:    loc[:speed],
          heading:  loc[:direction],
          timestamp: loc[:timestamp].strftime("%F %T")
        }
      )
    end
  end
end
