class DeliveryChannel < ApplicationCable::Channel
  def subscribed
    delivery_request = find_delivery_request
    if delivery_request && authorized_for_delivery?(delivery_request)
      stream_from "delivery_request_#{delivery_request.id}"
      Rails.logger.info "User #{current_user.id} subscribed to delivery_request_#{delivery_request.id}"
    else
      reject
    end
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
    Rails.logger.info "User #{current_user&.id} unsubscribed from delivery channel"
  end

  def update_location(data)
    delivery_request = find_delivery_request
    driver = current_user.driver if current_user.respond_to?(:driver)
    
    return unless delivery_request && driver && delivery_request.driver == driver

    lat = data['latitude'].to_f
    lng = data['longitude'].to_f
    accuracy = data['accuracy']&.to_f
    speed = data['speed']&.to_f
    bearing = data['bearing']&.to_f

    if valid_coordinates?(lat, lng)
      driver.update_location(lat, lng, accuracy, speed, bearing)
      
      # Broadcast updated location to all subscribers
      ActionCable.server.broadcast(
        "delivery_request_#{delivery_request.id}",
        {
          type: 'location_update',
          driver_location: {
            latitude: lat,
            longitude: lng,
            accuracy: accuracy,
            speed: speed,
            bearing: bearing,
            updated_at: Time.current.iso8601
          }
        }
      )
    end
  end

  def update_status(data)
    delivery_request = find_delivery_request
    driver = current_user.driver if current_user.respond_to?(:driver)
    
    return unless delivery_request && driver && delivery_request.driver == driver

    new_status = data['status']
    return unless DeliveryRequest.statuses.key?(new_status)

    case new_status
    when 'picked_up'
      delivery_request.pickup! if delivery_request.assigned?
    when 'in_transit'
      delivery_request.mark_in_transit! if delivery_request.picked_up?
    when 'delivered'
      delivery_request.deliver! if delivery_request.picked_up? || delivery_request.in_transit?
    end
  end

  private

  def find_delivery_request
    @delivery_request ||= DeliveryRequest.find(params[:delivery_request_id]) if params[:delivery_request_id]
  end

  def authorized_for_delivery?(delivery_request)
    # Customer can view their own delivery
    return true if current_user == delivery_request.customer
    
    # Driver can view their assigned delivery
    return true if current_user.respond_to?(:driver) && current_user.driver == delivery_request.driver
    
    # Fleet provider admin can view their deliveries
    return true if current_user.fleet_provider_users.exists?(fleet_provider: delivery_request.fleet_provider)
    
    false
  end

  def valid_coordinates?(lat, lng)
    lat.between?(-90, 90) && lng.between?(-180, 180)
  end
end