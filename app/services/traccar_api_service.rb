class TraccarApiService
  class TraccarError < StandardError; end
  class AuthenticationError < TraccarError; end
  class NotFoundError < TraccarError; end

  include HTTParty
  base_uri ENV.fetch('TRACCAR_BASE_URL', 'http://178.62.101.24:8000')

  def initialize(email = nil, password = nil)
    email    ||= ENV.fetch('TRACCAR_EMAIL', 'admin')
    password ||= ENV.fetch('TRACCAR_PASSWORD', 'admin')
    @auth = { basic_auth: { username: email, password: password } }
  end

  # List all devices registered in Traccar
  def devices
    response = self.class.get('/api/devices', @auth)
    handle_response(response)
  end

  # Fetch a single Traccar device by its Traccar ID
  def device(traccar_id)
    response = self.class.get("/api/devices/#{traccar_id}", @auth)
    handle_response(response)
  end

  # Latest position(s) — pass device_id to scope to one device
  def positions(device_id: nil)
    opts = @auth.dup
    opts[:query] = { deviceId: device_id } if device_id
    response = self.class.get('/api/positions', opts)
    handle_response(response)
  end

  # Update mutable fields on a Traccar device (name, groupId, etc.)
  # Traccar requires the full device object on PUT, so we fetch first.
  def update_device(traccar_id, attributes)
    current = device(traccar_id)
    return nil unless current.is_a?(Hash)

    body = current.merge(attributes.stringify_keys)
    response = self.class.put(
      "/api/devices/#{traccar_id}",
      @auth.merge(body: body.to_json, headers: { 'Content-Type' => 'application/json' })
    )
    handle_response(response)
  end

  # Link a Traccar device to a Traccar driver via the permissions endpoint
  def link_driver(traccar_device_id, traccar_driver_id)
    response = self.class.post(
      '/api/permissions',
      @auth.merge(body: { deviceId: traccar_device_id, driverId: traccar_driver_id }.to_json,
                  headers: { 'Content-Type' => 'application/json' })
    )
    handle_response(response)
  end

  private

  def handle_response(response)
    case response.code
    when 200, 201, 204
      response.parsed_response
    when 401
      raise AuthenticationError, 'Invalid Traccar credentials'
    when 404
      raise NotFoundError, 'Traccar resource not found'
    else
      raise TraccarError, "Traccar API error #{response.code}: #{response.message}"
    end
  rescue HTTParty::Error, Timeout::Error, Errno::ECONNREFUSED => e
    Rails.logger.error("Traccar connection error: #{e.message}")
    raise TraccarError, "Traccar server unavailable: #{e.message}"
  end
end
