class DevicesController < ApplicationController
  before_action :authorize_device_access!
  before_action :set_device, only: [ :show, :edit, :update, :ping ]

  def new
    @vehicle = Vehicle.find_by(id: params[:vehicle_id])
    @device  = Device.new(vehicle_id: @vehicle&.id)
    begin
      @available_traccar_devices = unlinked_traccar_devices
    rescue TraccarApiService::TraccarError => e
      @available_traccar_devices = []
      @traccar_error = e.message
    end
  end

  def show
    if @device.traccar_id.present?
      begin
        svc = TraccarApiService.new
        @traccar_device   = svc.device(@device.traccar_id)
        positions         = svc.positions(device_id: @device.traccar_id)
        @traccar_position = Array(positions).first
      rescue TraccarApiService::TraccarError => e
        @traccar_error = e.message
      end
    else
      begin
        @available_traccar_devices = unlinked_traccar_devices
      rescue TraccarApiService::TraccarError => e
        @available_traccar_devices = []
        @traccar_error = e.message
      end
    end
  end

  def ping
    socket = find_jt808_socket

    if socket
      begin
        socket.write("PING\n")
        flash[:notice] = "JT808 ping sent to #{@device.name.presence || @device.terminal_id}"
      rescue => e
        Rails.logger.error "JT808 ping failed: #{e.message}"
        flash[:alert] = "JT808 ping failed: #{e.message}"
      end
      return redirect_back(fallback_location: device_path(@device))
    end

    if @device.traccar_id.present?
      begin
        positions = TraccarApiService.new.positions(device_id: @device.traccar_id)
        latest    = Array(positions).first
        if latest
          device_time = latest["deviceTime"] ? Time.parse(latest["deviceTime"]).strftime("%b %d, %Y %H:%M") : "unknown time"
          @device.update_column(:last_seen_at, Time.current)
          flash[:notice] = "Traccar confirms device last reported at #{device_time}."
        else
          flash[:alert] = "No position data from Traccar yet — device may not have reported."
        end
      rescue TraccarApiService::TraccarError => e
        flash[:alert] = "Traccar ping failed: #{e.message}"
      end
    else
      flash[:alert] = "Device is not connected via JT808 and is not linked to Traccar."
    end

    redirect_back fallback_location: device_path(@device)
  end

  def create
    @device = Device.new(device_params)
    if @device.save
      redirect_to @device.vehicle || devices_path, notice: "GPS Device registered successfully"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @device.update(device_params)
      redirect_to @device.vehicle || devices_path, notice: "Device updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def authorize_device_access!
    unless current_user.admin? || current_user.fleet_provider_admin?
      redirect_to root_path, alert: "You are not authorized to manage devices."
    end
  end

  def fleet_vehicle_scope
    current_user.admin? ? Vehicle.all : Vehicle.where(fleet_provider_id: current_user.fleet_provider_ids)
  end

  def set_device
    @device = Device.joins(:vehicle).merge(fleet_vehicle_scope).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Device not found."
  end

  def device_params
    params.require(:device).permit(:terminal_id, :sim_number, :name, :vehicle_id, :status, :traccar_id)
  end

  def find_jt808_socket
    ids = [ @device.terminal_id, @device.sim_number ].compact

    ids.each do |id|
      socket = Jt808::Registry.get_socket(id)
      return socket if socket

      numeric = id.gsub(/[^0-9]/, "")
      socket  = Jt808::Registry.get_socket(numeric)
      return socket if socket
    end

    nil
  end

  def unlinked_traccar_devices
    all      = TraccarApiService.new.devices || []
    used_ids = Device.where.not(traccar_id: nil).pluck(:traccar_id)
    all.reject { |td| used_ids.include?(td["id"]) }
  end
end
