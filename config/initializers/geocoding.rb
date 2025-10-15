# Geocoding service configuration
Rails.application.configure do
  config.geocoding = ActiveSupport::OrderedOptions.new
  
  # Default geocoding provider
  # Options: :nominatim (OpenStreetMap - free), :google (Google Maps API - requires key)
  config.geocoding.provider = :nominatim
  
  # Rate limiting (requests per minute)
  config.geocoding.rate_limit = 60
  
  # Request timeout (in seconds)
  config.geocoding.timeout = 5
  
  # Cache geocoding results (in seconds, nil to disable)
  config.geocoding.cache_ttl = 86400 # 24 hours
  
  # Google Maps API key (if using Google provider)
  # config.geocoding.google_api_key = ENV['GOOGLE_MAPS_API_KEY']
  
  # User agent string for requests
  config.geocoding.user_agent = "FleetCoreEngine/1.0 (contact@example.com)"
end

# Optional: Configure Rails.cache for geocoding results caching
# Uncomment if you want to enable caching
=begin
Rails.application.config.after_initialize do
  # Simple in-memory cache for geocoding results
  GeocodingService.class_eval do
    def self.cached_geocode(address)
      cache_key = "geocode:#{Digest::MD5.hexdigest(address.to_s.downcase)}"
      
      Rails.cache.fetch(cache_key, expires_in: Rails.application.config.geocoding.cache_ttl) do
        geocode(address)
      end
    end
    
    def self.cached_reverse_geocode(latitude, longitude)
      cache_key = "reverse_geocode:#{latitude},#{longitude}"
      
      Rails.cache.fetch(cache_key, expires_in: Rails.application.config.geocoding.cache_ttl) do
        reverse_geocode(latitude, longitude)
      end
    end
  end
end
=end