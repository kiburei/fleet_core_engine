class DeliveryDispatchService
  def initialize(delivery_request)
    @delivery_request = delivery_request
    @fleet_provider = delivery_request.fleet_provider
  end

  def find_and_assign_driver(options = {})
    return false unless @delivery_request.can_be_assigned?

    driver = find_best_driver(options)
    return false unless driver

    begin
      @delivery_request.assign_to_driver!(driver)
      notify_nearby_drivers if options[:notify_nearby]
      true
    rescue => e
      Rails.logger.error "Failed to assign delivery #{@delivery_request.request_number} to driver #{driver.id}: #{e.message}"
      false
    end
  end

  def find_available_drivers(radius_km: nil)
    radius = radius_km || @fleet_provider.delivery_radius_km || 50
    
    @fleet_provider.available_drivers_for_delivery(
      @delivery_request.pickup_latitude,
      @delivery_request.pickup_longitude,
      radius
    )
  end

  def estimate_delivery_time(driver = nil)
    driver ||= find_best_driver
    return nil unless driver

    # Calculate travel time to pickup location
    pickup_travel_time = calculate_travel_time(
      driver.current_latitude,
      driver.current_longitude,
      @delivery_request.pickup_latitude,
      @delivery_request.pickup_longitude
    )

    # Calculate delivery time from pickup to destination
    delivery_travel_time = calculate_travel_time(
      @delivery_request.pickup_latitude,
      @delivery_request.pickup_longitude,
      @delivery_request.delivery_latitude,
      @delivery_request.delivery_longitude
    )

    # Add buffer time for pickup and delivery
    buffer_time = 10 # 10 minutes buffer

    total_time = pickup_travel_time + delivery_travel_time + buffer_time
    
    # Update the delivery request with estimated duration
    @delivery_request.update_column(:estimated_duration_minutes, total_time.round)
    
    total_time
  end

  def broadcast_to_available_drivers
    available_drivers = find_available_drivers
    
    delivery_data = {
      type: 'new_delivery_available',
      delivery_request: {
        id: @delivery_request.id,
        request_number: @delivery_request.request_number,
        pickup_address: @delivery_request.pickup_address,
        delivery_address: @delivery_request.delivery_address,
        delivery_fee: @delivery_request.delivery_fee,
        currency: 'KES',
        estimated_distance_km: @delivery_request.distance_km,
        priority: @delivery_request.priority,
        created_at: @delivery_request.created_at.iso8601
      }
    }

    available_drivers.find_each do |driver|
      # Calculate driver-specific info
      distance_to_pickup = driver.distance_to(
        @delivery_request.pickup_latitude,
        @delivery_request.pickup_longitude
      )
      
      driver_data = delivery_data.deep_dup
      driver_data[:delivery_request][:distance_to_pickup_km] = distance_to_pickup&.round(2)
      driver_data[:delivery_request][:estimated_pickup_time] = estimate_pickup_time(driver)
      
      ActionCable.server.broadcast(
        "driver_location_#{driver.id}",
        driver_data
      )
    end
    
    available_drivers.count
  end

  private

  def find_best_driver(options = {})
    available_drivers = find_available_drivers(radius_km: options[:radius_km])
    return nil if available_drivers.empty?

    # Score drivers based on multiple factors
    scored_drivers = available_drivers.map do |driver|
      score = calculate_driver_score(driver)
      { driver: driver, score: score }
    end

    # Sort by score (higher is better) and return the best driver
    best_match = scored_drivers.max_by { |item| item[:score] }
    best_match[:driver]
  end

  def calculate_driver_score(driver)
    # Distance factor (closer is better)
    distance = driver.distance_to(
      @delivery_request.pickup_latitude,
      @delivery_request.pickup_longitude
    )
    distance_score = 100 - [distance, 100].min

    # Rating factor
    rating_score = driver.delivery_rating * 20 # Convert 5-star to 100 scale

    # Priority factor (urgent deliveries get priority treatment)
    priority_bonus = case @delivery_request.priority
                    when 'urgent' then 50
                    when 'high' then 25
                    else 0
                    end

    # Experience factor
    experience_score = [driver.total_deliveries, 100].min

    # Combine scores with weights
    total_score = (distance_score * 0.4) + 
                  (rating_score * 0.3) + 
                  (experience_score * 0.2) + 
                  priority_bonus

    total_score.round(2)
  end

  def calculate_travel_time(from_lat, from_lng, to_lat, to_lng)
    # Simple estimate: distance / average speed
    # In production, you'd use a routing service like Google Maps API
    
    distance_km = calculate_distance(from_lat, from_lng, to_lat, to_lng)
    average_speed_kmh = 30 # Assume 30 km/h average speed in city
    
    (distance_km / average_speed_kmh * 60).round # Convert to minutes
  end

  def calculate_distance(lat1, lng1, lat2, lng2)
    # Haversine formula
    rad_per_deg = Math::PI / 180
    rkm = 6371
    
    dlat_rad = (lat2 - lat1) * rad_per_deg
    dlon_rad = (lng2 - lng1) * rad_per_deg
    
    lat1_rad = lat1 * rad_per_deg
    lat2_rad = lat2 * rad_per_deg
    
    a = Math.sin(dlat_rad/2)**2 + Math.cos(lat1_rad) * Math.cos(lat2_rad) * Math.sin(dlon_rad/2)**2
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
    
    rkm * c
  end

  def estimate_pickup_time(driver)
    travel_time = calculate_travel_time(
      driver.current_latitude,
      driver.current_longitude,
      @delivery_request.pickup_latitude,
      @delivery_request.pickup_longitude
    )
    
    Time.current + travel_time.minutes
  end

  def notify_nearby_drivers
    # This could send push notifications to drivers who weren't assigned
    # but are nearby, in case the assigned driver declines
    Rails.logger.info "Notifying nearby drivers about delivery #{@delivery_request.request_number}"
  end
end