class Api::V1::TraccarController < Api::V1::BaseController
  # These endpoints are used by the web admin UI (Devise session) as well as
  # mobile clients (JWT). Skip JWT auth and fall back to Devise instead.
  skip_before_action :authenticate_api_user!
  before_action :authenticate_user!
  before_action :authorize_traccar!

  before_action :set_vehicle, only: [ :assign_tracker, :position ]

  # GET /api/v1/traccar/devices
  # Lists all devices registered in Traccar so the client can pick one to assign.
  def devices
    traccar_devices = traccar_service.devices
    render_success({ devices: traccar_devices })
  rescue TraccarApiService::TraccarError => e
    render_error(e.message, :service_unavailable)
  end

  # POST /api/v1/traccar/vehicles/:vehicle_id/assign_tracker
  # Body: { traccar_id: <integer>, name: <string (optional)> }
  #
  # Finds or creates a Device record for this vehicle linked to the given Traccar
  # device ID, then renames the device in Traccar to the vehicle's registration
  # number so both systems stay in sync.
  def assign_tracker
    traccar_id = params.require(:traccar_id).to_i

    # Verify the Traccar device exists before touching local records
    traccar_device = traccar_service.device(traccar_id)

    device = @vehicle.devices.find_or_initialize_by(traccar_id: traccar_id)
    device.name   = params[:name].presence || traccar_device['name']
    device.status = 'active'

    if device.save
      traccar_service.update_device(traccar_id, name: @vehicle.registration_number)
      render_success({ device: serialize_device(device) }, 'Tracker assigned to vehicle')
    else
      render_error('Failed to assign tracker', :unprocessable_entity, device.errors)
    end
  rescue TraccarApiService::NotFoundError
    render_error('Traccar device not found', :not_found)
  rescue TraccarApiService::AuthenticationError => e
    render_error(e.message, :unauthorized)
  rescue TraccarApiService::TraccarError => e
    render_error(e.message, :service_unavailable)
  end

  # GET /api/v1/traccar/vehicles/:vehicle_id/position
  # Returns the latest Traccar position for the vehicle's linked tracker.
  # Optional param: ?traccar_id=<id> to target a specific device on the vehicle.
  def position
    device = resolve_traccar_device

    unless device
      return render_error('No Traccar device linked to this vehicle', :not_found)
    end

    positions = traccar_service.positions(device_id: device.traccar_id)
    latest    = Array(positions).first

    unless latest
      return render_error('No position data available for this device', :not_found)
    end

    render_success({
      vehicle_id: @vehicle.id,
      registration_number: @vehicle.registration_number,
      traccar_device_id: device.traccar_id,
      position: {
        latitude:    latest['latitude'],
        longitude:   latest['longitude'],
        speed:       latest['speed'],
        course:      latest['course'],
        altitude:    latest['altitude'],
        accuracy:    latest['accuracy'],
        address:     latest['address'],
        recorded_at: latest['deviceTime']
      }
    })
  rescue TraccarApiService::TraccarError => e
    render_error(e.message, :service_unavailable)
  end

  private

  def authorize_traccar!
    unless current_user.admin? || current_user.fleet_provider_admin?
      render_error('You are not authorized to access tracker management', :forbidden)
    end
  end

  def set_vehicle
    scope = current_user.admin? ? Vehicle.all : Vehicle.where(fleet_provider_id: current_user.fleet_provider_ids)
    @vehicle = scope.find(params[:vehicle_id])
  rescue ActiveRecord::RecordNotFound
    render_error('Vehicle not found', :not_found)
  end

  def traccar_service
    @traccar_service ||= TraccarApiService.new
  end

  def resolve_traccar_device
    if params[:traccar_id].present?
      @vehicle.devices.find_by(traccar_id: params[:traccar_id].to_i)
    else
      @vehicle.devices.where.not(traccar_id: nil).order(updated_at: :desc).first
    end
  end

  def serialize_device(device)
    {
      id:          device.id,
      traccar_id:  device.traccar_id,
      name:        device.name,
      status:      device.status,
      vehicle_id:  device.vehicle_id,
      terminal_id: device.terminal_id,
      sim_number:  device.sim_number
    }
  end
end
