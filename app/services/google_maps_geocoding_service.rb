class GoogleMapsGeocodingService
  class GeocodingError < StandardError; end
  class RateLimitError < GeocodingError; end
  class InvalidAddressError < GeocodingError; end

  include HTTParty
  base_uri 'https://maps.googleapis.com/maps/api'

  def initialize
    @api_key = Rails.application.credentials.dig(:google_maps, :api_key) || 
               ENV['GOOGLE_MAPS_API_KEY']
    
    raise GeocodingError, "Google Maps API key not configured" if @api_key.blank?
  end

  def self.geocode(address)
    new.geocode(address)
  end

  def self.reverse_geocode(latitude, longitude)
    new.reverse_geocode(latitude, longitude)
  end

  def self.search_places(query, limit: 5)
    new.search_places(query, limit: limit)
  end

  def geocode(address)
    return nil if address.blank?

    Rails.logger.info("Geocoding address with Google Maps: #{address}")

    response = self.class.get('/geocode/json', {
      query: {
        address: address,
        key: @api_key
      }
    })

    handle_google_response(response) do |data|
      if data['results'].any?
        result = data['results'].first
        location = result['geometry']['location']
        {
          latitude: location['lat'].to_f,
          longitude: location['lng'].to_f,
          formatted_address: result['formatted_address'],
          place_id: result['place_id'],
          address_components: extract_google_address_components(result['address_components'])
        }
      else
        raise InvalidAddressError, "Address not found: #{address}"
      end
    end
  rescue HTTParty::Error, Timeout::Error => e
    Rails.logger.error("Google Maps API error: #{e.message}")
    raise GeocodingError, "Google Maps API unavailable: #{e.message}"
  end

  def reverse_geocode(latitude, longitude)
    return nil if latitude.blank? || longitude.blank?

    Rails.logger.info("Reverse geocoding coordinates with Google Maps: #{latitude}, #{longitude}")

    response = self.class.get('/geocode/json', {
      query: {
        latlng: "#{latitude},#{longitude}",
        key: @api_key
      }
    })

    handle_google_response(response) do |data|
      if data['results'].any?
        result = data['results'].first
        {
          formatted_address: result['formatted_address'],
          place_id: result['place_id'],
          address_components: extract_google_address_components(result['address_components'])
        }
      else
        nil
      end
    end
  rescue HTTParty::Error, Timeout::Error => e
    Rails.logger.error("Google Maps reverse geocoding API error: #{e.message}")
    raise GeocodingError, "Google Maps reverse geocoding service unavailable: #{e.message}"
  end

  def search_places(query, limit: 5)
    return [] if query.blank? || query.length < 3

    Rails.logger.info("Searching places with Google Maps: #{query}")

    response = self.class.get('/place/autocomplete/json', {
      query: {
        input: query,
        key: @api_key
      }
    })

    handle_google_response(response) do |data|
      predictions = data['predictions'] || []
      predictions.first(limit).map do |prediction|
        {
          place_id: prediction['place_id'],
          formatted_address: prediction['description'],
          place_type: prediction['types']&.first,
          reference: prediction['reference']
        }
      end
    end
  rescue HTTParty::Error, Timeout::Error => e
    Rails.logger.error("Google Maps places search API error: #{e.message}")
    raise GeocodingError, "Google Maps places search service unavailable: #{e.message}"
  end

  private

  def handle_google_response(response)
    case response.code
    when 200
      data = response.parsed_response
      case data['status']
      when 'OK'
        yield(data) if block_given?
      when 'ZERO_RESULTS'
        raise InvalidAddressError, "No results found"
      when 'OVER_QUERY_LIMIT', 'OVER_DAILY_LIMIT'
        raise RateLimitError, "Google Maps API quota exceeded"
      when 'REQUEST_DENIED'
        raise GeocodingError, "Google Maps API request denied - check your API key"
      when 'INVALID_REQUEST'
        raise InvalidAddressError, "Invalid request parameters"
      else
        raise GeocodingError, "Google Maps API error: #{data['status']}"
      end
    else
      raise GeocodingError, "Google Maps API returned #{response.code}: #{response.message}"
    end
  end

  def extract_google_address_components(components)
    result = {}
    
    components.each do |component|
      types = component['types']
      
      if types.include?('street_number')
        result[:house_number] = component['long_name']
      elsif types.include?('route')
        result[:street] = component['long_name']
      elsif types.include?('neighborhood') || types.include?('sublocality')
        result[:neighborhood] = component['long_name']
      elsif types.include?('locality')
        result[:city] = component['long_name']
      elsif types.include?('administrative_area_level_2')
        result[:county] = component['long_name']
      elsif types.include?('administrative_area_level_1')
        result[:state] = component['long_name']
      elsif types.include?('postal_code')
        result[:postcode] = component['long_name']
      elsif types.include?('country')
        result[:country] = component['long_name']
        result[:country_code] = component['short_name']
      end
    end
    
    result
  end
end