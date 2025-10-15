class Api::V1::LocationsController < Api::V1::BaseController
  # GET /api/v1/locations/search?query=nairobi&limit=5
  def search
    query = params[:query]
    limit = [params[:limit]&.to_i || 5, 10].min # Max 10 results

    if query.blank? || query.length < 3
      return render_error('Query must be at least 3 characters long', :unprocessable_entity)
    end

    begin
      places = GeocodingService.search_places(query, limit: limit)
      
      render_success({
        places: places.map do |place|
          {
            place_id: place[:place_id],
            formatted_address: place[:formatted_address],
            latitude: place[:latitude],
            longitude: place[:longitude],
            place_type: place[:place_type],
            importance: place[:importance],
            address_components: format_address_components(place[:address_components])
          }
        end,
        query: query,
        total_results: places.length
      })
    rescue GeocodingService::GeocodingError => e
      render_error("Location search failed: #{e.message}", :service_unavailable)
    rescue => e
      Rails.logger.error("Location search error: #{e.message}")
      render_error('Location search service temporarily unavailable', :internal_server_error)
    end
  end

  # POST /api/v1/locations/geocode
  # Body: { "address": "123 Main St, Nairobi, Kenya" }
  def geocode
    address = params[:address]

    if address.blank?
      return render_error('Address is required', :unprocessable_entity)
    end

    begin
      result = GeocodingService.geocode(address)
      
      if result
        render_success({
          location: {
            latitude: result[:latitude],
            longitude: result[:longitude],
            formatted_address: result[:formatted_address],
            place_id: result[:place_id],
            address_components: format_address_components(result[:address_components])
          },
          input_address: address
        })
      else
        render_error('Address not found', :not_found)
      end
    rescue GeocodingService::InvalidAddressError => e
      render_error(e.message, :not_found)
    rescue GeocodingService::RateLimitError => e
      render_error('Geocoding service rate limit exceeded. Please try again later.', :too_many_requests)
    rescue GeocodingService::GeocodingError => e
      render_error("Geocoding failed: #{e.message}", :service_unavailable)
    rescue => e
      Rails.logger.error("Geocoding error: #{e.message}")
      render_error('Geocoding service temporarily unavailable', :internal_server_error)
    end
  end

  # POST /api/v1/locations/reverse_geocode
  # Body: { "latitude": -1.2921, "longitude": 36.8219 }
  def reverse_geocode
    latitude = params[:latitude]&.to_f
    longitude = params[:longitude]&.to_f

    unless latitude&.between?(-90, 90) && longitude&.between?(-180, 180)
      return render_error('Valid latitude (-90 to 90) and longitude (-180 to 180) are required', :unprocessable_entity)
    end

    begin
      result = GeocodingService.reverse_geocode(latitude, longitude)
      
      if result
        render_success({
          location: {
            latitude: latitude,
            longitude: longitude,
            formatted_address: result[:formatted_address],
            place_id: result[:place_id],
            address_components: format_address_components(result[:address_components])
          }
        })
      else
        render_error('Location not found', :not_found)
      end
    rescue GeocodingService::GeocodingError => e
      render_error("Reverse geocoding failed: #{e.message}", :service_unavailable)
    rescue => e
      Rails.logger.error("Reverse geocoding error: #{e.message}")
      render_error('Reverse geocoding service temporarily unavailable', :internal_server_error)
    end
  end

  # POST /api/v1/locations/validate_coordinates
  # Body: { "pickup_address": "...", "delivery_address": "..." }
  # This endpoint validates and geocodes multiple addresses in one request
  def validate_coordinates
    pickup_address = params[:pickup_address]
    delivery_address = params[:delivery_address]
    pickup_lat = params[:pickup_latitude]&.to_f
    pickup_lng = params[:pickup_longitude]&.to_f
    delivery_lat = params[:delivery_latitude]&.to_f
    delivery_lng = params[:delivery_longitude]&.to_f

    result = { pickup: {}, delivery: {} }
    errors = []

    # Handle pickup location
    if pickup_address.present?
      begin
        pickup_geocoded = GeocodingService.geocode(pickup_address)
        result[:pickup] = {
          address: pickup_geocoded[:formatted_address],
          latitude: pickup_geocoded[:latitude],
          longitude: pickup_geocoded[:longitude],
          place_id: pickup_geocoded[:place_id],
          source: 'geocoded'
        }
      rescue GeocodingService::GeocodingError => e
        errors << "Pickup address geocoding failed: #{e.message}"
      end
    elsif pickup_lat && pickup_lng
      result[:pickup] = {
        latitude: pickup_lat,
        longitude: pickup_lng,
        source: 'coordinates'
      }
      
      # Optionally reverse geocode to get address
      begin
        reverse_result = GeocodingService.reverse_geocode(pickup_lat, pickup_lng)
        result[:pickup][:address] = reverse_result[:formatted_address] if reverse_result
      rescue GeocodingService::GeocodingError
        # Ignore reverse geocoding failures
      end
    else
      errors << "Pickup location: either address or coordinates are required"
    end

    # Handle delivery location
    if delivery_address.present?
      begin
        delivery_geocoded = GeocodingService.geocode(delivery_address)
        result[:delivery] = {
          address: delivery_geocoded[:formatted_address],
          latitude: delivery_geocoded[:latitude],
          longitude: delivery_geocoded[:longitude],
          place_id: delivery_geocoded[:place_id],
          source: 'geocoded'
        }
      rescue GeocodingService::GeocodingError => e
        errors << "Delivery address geocoding failed: #{e.message}"
      end
    elsif delivery_lat && delivery_lng
      result[:delivery] = {
        latitude: delivery_lat,
        longitude: delivery_lng,
        source: 'coordinates'
      }
      
      # Optionally reverse geocode to get address
      begin
        reverse_result = GeocodingService.reverse_geocode(delivery_lat, delivery_lng)
        result[:delivery][:address] = reverse_result[:formatted_address] if reverse_result
      rescue GeocodingService::GeocodingError
        # Ignore reverse geocoding failures
      end
    else
      errors << "Delivery location: either address or coordinates are required"
    end

    if errors.any?
      render_error(errors.join('; '), :unprocessable_entity)
    else
      # Calculate distance if both locations are valid
      if result[:pickup][:latitude] && result[:delivery][:latitude]
        distance = calculate_distance(
          result[:pickup][:latitude], result[:pickup][:longitude],
          result[:delivery][:latitude], result[:delivery][:longitude]
        )
        result[:estimated_distance_km] = distance.round(2)
      end

      render_success({
        locations: result,
        valid: true
      })
    end
  rescue => e
    Rails.logger.error("Location validation error: #{e.message}")
    render_error('Location validation service temporarily unavailable', :internal_server_error)
  end

  private

  def format_address_components(components)
    return {} unless components.is_a?(Hash)
    
    {
      house_number: components[:house_number],
      street: components[:street],
      neighborhood: components[:neighborhood],
      city: components[:city],
      county: components[:county],
      state: components[:state],
      postcode: components[:postcode],
      country: components[:country],
      country_code: components[:country_code]
    }.compact
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
end