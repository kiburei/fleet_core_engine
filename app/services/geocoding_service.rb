class GeocodingService
  class GeocodingError < StandardError; end
  class RateLimitError < GeocodingError; end
  class InvalidAddressError < GeocodingError; end

  include HTTParty
  
  # You can switch between different geocoding providers
  # For this example, I'll use OpenStreetMap's Nominatim (free)
  # You can easily switch to Google Maps API by changing the base_uri and methods
  base_uri 'https://nominatim.openstreetmap.org'

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

    Rails.logger.info("Geocoding address: #{address}")

    response = self.class.get('/search', {
      query: {
        q: address,
        format: 'json',
        limit: 1,
        addressdetails: 1
      },
      headers: {
        'User-Agent' => 'FleetCoreEngine/1.0 (contact@example.com)'
      }
    })

    handle_response(response) do |data|
      if data.any?
        result = data.first
        {
          latitude: result['lat'].to_f,
          longitude: result['lon'].to_f,
          formatted_address: result['display_name'],
          place_id: result['place_id'],
          address_components: extract_address_components(result)
        }
      else
        raise InvalidAddressError, "Address not found: #{address}"
      end
    end
  rescue HTTParty::Error, Timeout::Error => e
    Rails.logger.error("Geocoding API error: #{e.message}")
    raise GeocodingError, "Geocoding service unavailable: #{e.message}"
  end

  def reverse_geocode(latitude, longitude)
    return nil if latitude.blank? || longitude.blank?

    Rails.logger.info("Reverse geocoding coordinates: #{latitude}, #{longitude}")

    response = self.class.get('/reverse', {
      query: {
        lat: latitude,
        lon: longitude,
        format: 'json',
        addressdetails: 1
      },
      headers: {
        'User-Agent' => 'FleetCoreEngine/1.0 (contact@example.com)'
      }
    })

    handle_response(response) do |data|
      {
        formatted_address: data['display_name'],
        place_id: data['place_id'],
        address_components: extract_address_components(data)
      }
    end
  rescue HTTParty::Error, Timeout::Error => e
    Rails.logger.error("Reverse geocoding API error: #{e.message}")
    raise GeocodingError, "Reverse geocoding service unavailable: #{e.message}"
  end

  def search_places(query, limit: 5)
    return [] if query.blank? || query.length < 3

    Rails.logger.info("Searching places: #{query}")

    response = self.class.get('/search', {
      query: {
        q: query,
        format: 'json',
        limit: limit,
        addressdetails: 1
      },
      headers: {
        'User-Agent' => 'FleetCoreEngine/1.0 (contact@example.com)'
      }
    })

    handle_response(response) do |data|
      data.map do |result|
        {
          place_id: result['place_id'],
          formatted_address: result['display_name'],
          latitude: result['lat'].to_f,
          longitude: result['lon'].to_f,
          place_type: result['type'],
          importance: result['importance']&.to_f,
          address_components: extract_address_components(result)
        }
      end
    end
  rescue HTTParty::Error, Timeout::Error => e
    Rails.logger.error("Places search API error: #{e.message}")
    raise GeocodingError, "Places search service unavailable: #{e.message}"
  end

  private

  def handle_response(response)
    case response.code
    when 200
      data = response.parsed_response
      yield(data) if block_given?
    when 429
      raise RateLimitError, "Geocoding rate limit exceeded"
    when 400
      raise InvalidAddressError, "Invalid request parameters"
    else
      raise GeocodingError, "Geocoding API returned #{response.code}: #{response.message}"
    end
  end

  def extract_address_components(result)
    address = result['address'] || {}
    {
      house_number: address['house_number'],
      street: address['road'],
      neighborhood: address['neighbourhood'] || address['suburb'],
      city: address['city'] || address['town'] || address['village'],
      county: address['county'],
      state: address['state'],
      postcode: address['postcode'],
      country: address['country'],
      country_code: address['country_code']
    }
  end
end

# Alternative Google Maps implementation (commented out)
# Uncomment and configure if you prefer Google Maps API
=begin
class GoogleMapsGeocodingService < GeocodingService
  include HTTParty
  base_uri 'https://maps.googleapis.com/maps/api'

  def initialize
    @api_key = Rails.application.credentials.dig(:google_maps, :api_key) || 
               ENV['GOOGLE_MAPS_API_KEY']
    
    raise GeocodingError, "Google Maps API key not configured" if @api_key.blank?
  end

  def geocode(address)
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
          latitude: location['lat'],
          longitude: location['lng'],
          formatted_address: result['formatted_address'],
          place_id: result['place_id'],
          address_components: result['address_components']
        }
      else
        raise InvalidAddressError, "Address not found: #{address}"
      end
    end
  end

  def reverse_geocode(latitude, longitude)
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
          address_components: result['address_components']
        }
      else
        nil
      end
    end
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
      when 'OVER_QUERY_LIMIT'
        raise RateLimitError, "Google Maps API quota exceeded"
      when 'REQUEST_DENIED'
        raise GeocodingError, "Google Maps API request denied"
      when 'INVALID_REQUEST'
        raise InvalidAddressError, "Invalid request parameters"
      else
        raise GeocodingError, "Google Maps API error: #{data['status']}"
      end
    else
      raise GeocodingError, "Google Maps API returned #{response.code}: #{response.message}"
    end
  end
end
=end