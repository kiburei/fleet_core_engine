class Api::V1::DeliveryRequestsController < Api::V1::BaseController
  before_action :ensure_driver
  before_action :set_delivery_request, only: [:show, :accept, :decline, :pickup, :mark_in_transit, :deliver, :cancel]

  def index
    # Get deliveries for the current driver
    deliveries = current_driver.delivery_requests
    
    # Filter by status if provided
    if params[:status].present? && DeliveryRequest.statuses.key?(params[:status])
      deliveries = deliveries.where(status: params[:status])
    end
    
    # Default to recent deliveries
    deliveries = deliveries.recent.includes(:marketplace_order, :customer)
    
    paginated_deliveries = paginate_collection(deliveries)

    render_success({
      delivery_requests: paginated_deliveries.map { |delivery| delivery_request_data(delivery) },
      pagination: pagination_meta(paginated_deliveries)
    })
  end

  def available
    # Get available deliveries in the area
    return render_error('Driver must be online to see available deliveries', :forbidden) unless current_driver.is_online?
    return render_error('Driver location not available', :unprocessable_entity) unless current_driver.current_location

    available_deliveries = DeliveryRequest.unassigned
                                        .joins(:fleet_provider)
                                        .where(fleet_provider: current_driver.fleet_provider)
                                        .recent

    # Filter by distance if driver has location
    if current_driver.current_latitude && current_driver.current_longitude
      radius_km = current_driver.max_delivery_distance_km
      
      available_deliveries = available_deliveries.where(
        "(6371 * acos(cos(radians(?)) * cos(radians(pickup_latitude)) * cos(radians(pickup_longitude) - radians(?)) + sin(radians(?)) * sin(radians(pickup_latitude)))) <= ?",
        current_driver.current_latitude, current_driver.current_longitude, 
        current_driver.current_latitude, radius_km
      )
    end

    paginated_deliveries = paginate_collection(available_deliveries.includes(:marketplace_order, :customer))

    deliveries_data = paginated_deliveries.map do |delivery|
      data = delivery_request_data(delivery)
      
      # Add driver-specific information
      if current_driver.current_location
        distance = current_driver.distance_to(delivery.pickup_latitude, delivery.pickup_longitude)
        data[:distance_to_pickup_km] = distance&.round(2)
        
        # Estimate pickup time
        if distance
          travel_time_minutes = (distance / 30.0 * 60).round # Assume 30 km/h average speed
          data[:estimated_pickup_time] = (Time.current + travel_time_minutes.minutes).iso8601
        end
      end
      
      data
    end

    render_success({
      delivery_requests: deliveries_data,
      pagination: pagination_meta(paginated_deliveries)
    })
  end

  def show
    render_success({ delivery_request: delivery_request_data(@delivery_request) })
  end

  def accept
    return render_error('Delivery not available for assignment', :unprocessable_entity) unless @delivery_request.can_be_assigned?
    return render_error('Driver not available', :forbidden) unless current_driver.available_for_new_delivery?

    begin
      @delivery_request.assign_to_driver!(current_driver)
      render_success(
        { delivery_request: delivery_request_data(@delivery_request) },
        'Delivery accepted successfully'
      )
    rescue ArgumentError => e
      render_error(e.message, :unprocessable_entity)
    end
  end

  def decline
    return render_error('Cannot decline unassigned delivery', :unprocessable_entity) unless @delivery_request.assigned?
    return render_error('Not your delivery', :forbidden) unless @delivery_request.driver == current_driver

    @delivery_request.update!(driver: nil, status: :pending)
    
    # Broadcast to find another driver
    DeliveryDispatchJob.perform_later(@delivery_request.id)

    render_success({}, 'Delivery declined successfully')
  end

  def pickup
    return render_error('Not your delivery', :forbidden) unless @delivery_request.driver == current_driver
    return render_error('Cannot pickup this delivery', :unprocessable_entity) unless @delivery_request.assigned?

    begin
      @delivery_request.pickup!
      render_success(
        { delivery_request: delivery_request_data(@delivery_request) },
        'Order picked up successfully'
      )
    rescue ArgumentError => e
      render_error(e.message, :unprocessable_entity)
    end
  end

  def mark_in_transit
    return render_error('Not your delivery', :forbidden) unless @delivery_request.driver == current_driver
    return render_error('Cannot mark as in transit', :unprocessable_entity) unless @delivery_request.picked_up?

    begin
      @delivery_request.mark_in_transit!
      render_success(
        { delivery_request: delivery_request_data(@delivery_request) },
        'Delivery marked as in transit'
      )
    rescue ArgumentError => e
      render_error(e.message, :unprocessable_entity)
    end
  end

  def deliver
    return render_error('Not your delivery', :forbidden) unless @delivery_request.driver == current_driver
    return render_error('Cannot deliver this order', :unprocessable_entity) unless @delivery_request.picked_up? || @delivery_request.in_transit?

    begin
      @delivery_request.deliver!
      render_success(
        { delivery_request: delivery_request_data(@delivery_request) },
        'Order delivered successfully'
      )
    rescue ArgumentError => e
      render_error(e.message, :unprocessable_entity)
    end
  end

  def cancel
    return render_error('Cannot cancel this delivery', :unprocessable_entity) unless @delivery_request.can_be_cancelled?
    
    # Only assigned driver or fleet admin can cancel
    unless @delivery_request.driver == current_driver || 
           current_user.fleet_provider_users.exists?(fleet_provider: @delivery_request.fleet_provider)
      return render_error('Not authorized to cancel this delivery', :forbidden)
    end

    cancellation_reason = params[:reason] || 'Cancelled by driver'
    
    begin
      @delivery_request.cancel!(cancellation_reason)
      render_success(
        { delivery_request: delivery_request_data(@delivery_request) },
        'Delivery cancelled successfully'
      )
    rescue ArgumentError => e
      render_error(e.message, :unprocessable_entity)
    end
  end

  def update_location
    return render_error('Driver must be online', :forbidden) unless current_driver.is_online?

    lat = params[:latitude].to_f
    lng = params[:longitude].to_f
    accuracy = params[:accuracy]&.to_f
    speed = params[:speed]&.to_f
    bearing = params[:bearing]&.to_f

    unless lat.between?(-90, 90) && lng.between?(-180, 180)
      return render_error('Invalid coordinates', :unprocessable_entity)
    end

    begin
      current_driver.update_location(lat, lng, accuracy, speed, bearing)
      render_success({
        current_location: current_driver.current_location,
        last_update: current_driver.last_location_update.iso8601
      }, 'Location updated successfully')
    rescue => e
      render_error("Failed to update location: #{e.message}")
    end
  end

  def driver_status
    render_success({
      driver: {
        id: current_driver.id,
        is_online: current_driver.is_online,
        is_available: current_driver.is_available_for_delivery,
        current_location: current_driver.current_location,
        current_delivery: current_driver.current_delivery ? delivery_request_data(current_driver.current_delivery) : nil
      }
    })
  end

  def go_online
    lat = params[:latitude]&.to_f
    lng = params[:longitude]&.to_f

    unless lat&.between?(-90, 90) && lng&.between?(-180, 180)
      return render_error('Valid coordinates required to go online', :unprocessable_entity)
    end

    current_driver.update!(
      is_online: true,
      is_available_for_delivery: true,
      current_latitude: lat,
      current_longitude: lng,
      last_location_update: Time.current
    )

    render_success({ driver: driver_status_data }, 'Driver is now online')
  end

  def go_offline
    current_driver.update!(
      is_online: false,
      is_available_for_delivery: false
    )

    render_success({ driver: driver_status_data }, 'Driver is now offline')
  end

  def toggle_availability
    return render_error('Driver must be online', :forbidden) unless current_driver.is_online?
    return render_error('Cannot change availability with active delivery', :unprocessable_entity) if current_driver.current_delivery

    available = params[:available] == true || params[:available] == 'true'
    current_driver.update!(is_available_for_delivery: available)

    render_success({ driver: driver_status_data }, 
                  "Driver is now #{available ? 'available' : 'unavailable'}")
  end

  private

  def ensure_driver
    return render_error('Driver profile required', :forbidden) unless current_driver
  end

  def set_delivery_request
    @delivery_request = DeliveryRequest.find(params[:id])
  end

  def delivery_request_data(delivery)
    {
      id: delivery.id,
      request_number: delivery.request_number,
      status: delivery.status,
      priority: delivery.priority,
      pickup_address: delivery.pickup_address,
      pickup_latitude: delivery.pickup_latitude,
      pickup_longitude: delivery.pickup_longitude,
      pickup_instructions: delivery.pickup_instructions,
      pickup_contact_name: delivery.pickup_contact_name,
      pickup_contact_phone: delivery.pickup_contact_phone,
      delivery_address: delivery.delivery_address,
      delivery_latitude: delivery.delivery_latitude,
      delivery_longitude: delivery.delivery_longitude,
      delivery_instructions: delivery.delivery_instructions,
      delivery_contact_name: delivery.delivery_contact_name,
      delivery_contact_phone: delivery.delivery_contact_phone,
      delivery_fee: delivery.delivery_fee,
      driver_commission: delivery.driver_commission,
      estimated_distance_km: delivery.estimated_distance_km,
      estimated_duration_minutes: delivery.estimated_duration_minutes,
      requested_at: delivery.requested_at.iso8601,
      assigned_at: delivery.assigned_at&.iso8601,
      picked_up_at: delivery.picked_up_at&.iso8601,
      delivered_at: delivery.delivered_at&.iso8601,
      cancelled_at: delivery.cancelled_at&.iso8601,
      cancellation_reason: delivery.cancellation_reason,
      estimated_delivery_time: delivery.estimated_delivery_time&.iso8601,
      delivery_progress: delivery.delivery_progress,
      business_customer: {
        name: delivery.business_customer&.business_name,
        contact_name: delivery.business_customer&.primary_contact_name,
        contact_phone: delivery.business_customer&.primary_contact_phone
      },
      end_customer: {
        name: delivery.end_customer_name,
        phone: delivery.end_customer_phone,
        email: delivery.end_customer_email
      },
      marketplace_order: {
        id: delivery.marketplace_order.id,
        order_number: delivery.marketplace_order.order_number,
        total_amount: delivery.marketplace_order.total_amount,
        total_items: delivery.marketplace_order.total_items
      }
    }
  end

  def driver_status_data
    {
      id: current_driver.id,
      is_online: current_driver.is_online,
      is_available: current_driver.is_available_for_delivery,
      current_location: current_driver.current_location,
      last_location_update: current_driver.last_location_update&.iso8601
    }
  end
end