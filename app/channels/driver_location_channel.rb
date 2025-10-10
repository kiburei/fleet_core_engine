class DriverLocationChannel < ApplicationCable::Channel
  def subscribed
    driver = find_driver
    if driver && authorized_for_driver?(driver)
      stream_from "driver_location_#{driver.id}"
      
      # Send current location on subscribe
      if driver.current_location
        transmit({
          type: 'current_location',
          latitude: driver.current_latitude,
          longitude: driver.current_longitude,
          updated_at: driver.last_location_update&.iso8601
        })
      end
      
      Rails.logger.info "User #{current_user.id} subscribed to driver_location_#{driver.id}"
    else
      reject
    end
  end

  def unsubscribed
    Rails.logger.info "User #{current_user&.id} unsubscribed from driver location channel"
  end

  def go_online(data)
    driver = current_user.driver if current_user.respond_to?(:driver)
    return unless driver && driver == find_driver

    lat = data['latitude']&.to_f
    lng = data['longitude']&.to_f

    if valid_coordinates?(lat, lng)
      driver.update!(
        is_online: true,
        is_available_for_delivery: true,
        current_latitude: lat,
        current_longitude: lng,
        last_location_update: Time.current
      )

      # Broadcast online status
      broadcast_driver_status(driver, 'online')
    end
  end

  def go_offline
    driver = current_user.driver if current_user.respond_to?(:driver)
    return unless driver && driver == find_driver

    driver.update!(
      is_online: false,
      is_available_for_delivery: false
    )

    # Broadcast offline status
    broadcast_driver_status(driver, 'offline')
  end

  def update_availability(data)
    driver = current_user.driver if current_user.respond_to?(:driver)
    return unless driver && driver == find_driver

    available = data['available'] == true
    driver.update!(is_available_for_delivery: available && driver.is_online?)

    # Broadcast availability status
    broadcast_driver_status(driver, available ? 'available' : 'busy')
  end

  private

  def find_driver
    @driver ||= Driver.find(params[:driver_id]) if params[:driver_id]
  end

  def authorized_for_driver?(driver)
    # Driver can access their own channel
    return true if current_user.respond_to?(:driver) && current_user.driver == driver
    
    # Fleet provider admin can access their drivers
    return true if current_user.fleet_provider_users.exists?(fleet_provider: driver.fleet_provider)
    
    false
  end

  def valid_coordinates?(lat, lng)
    lat&.between?(-90, 90) && lng&.between?(-180, 180)
  end

  def broadcast_driver_status(driver, status)
    ActionCable.server.broadcast(
      "driver_location_#{driver.id}",
      {
        type: 'status_update',
        status: status,
        is_online: driver.is_online?,
        is_available: driver.is_available_for_delivery?,
        updated_at: Time.current.iso8601
      }
    )

    # Also broadcast to fleet provider channel for admin dashboard
    ActionCable.server.broadcast(
      "fleet_provider_#{driver.fleet_provider_id}",
      {
        type: 'driver_status_update',
        driver_id: driver.id,
        driver_name: driver.full_name,
        status: status,
        is_online: driver.is_online?,
        is_available: driver.is_available_for_delivery?,
        current_location: driver.current_location,
        updated_at: Time.current.iso8601
      }
    )
  end
end