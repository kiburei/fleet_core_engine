module Admin
  class Jt808Controller < ApplicationController
    before_action :authenticate_user!
    before_action :ensure_admin

    def index
      # expose the registry keys (terminal ids) and device info
      keys = fetch_registry_keys
      devices_info = keys.map do |key|
        device = Device.find_by(terminal_id: key) || Device.find_by(sim_number: key)
        {
          registered_phone: key,
          device_id: device&.id,
          terminal_id: device&.terminal_id,
          sim_number: device&.sim_number,
          device_name: device&.name,
          status: device&.status,
          matched_by: device ? (device.terminal_id == key ? "terminal_id" : "sim_number") : "not_found"
        }
      end

      respond_to do |format|
        format.html do
          html = "<h2>JT808 Connected Devices</h2>"
          html += "<p>Total connected: #{keys.size}</p>"
          html += "<table border='1' cellpadding='5'>"
          html += "<tr><th>Registered Phone</th><th>Device ID</th><th>Terminal ID</th><th>SIM Number</th><th>Name</th><th>Status</th><th>Matched By</th></tr>"
          devices_info.each do |info|
            html += "<tr>"
            html += "<td>#{info[:registered_phone]}</td>"
            html += "<td>#{info[:device_id] || 'N/A'}</td>"
            html += "<td>#{info[:terminal_id] || 'N/A'}</td>"
            html += "<td>#{info[:sim_number] || 'N/A'}</td>"
            html += "<td>#{info[:device_name] || 'N/A'}</td>"
            html += "<td>#{info[:status] || 'N/A'}</td>"
            html += "<td>#{info[:matched_by]}</td>"
            html += "</tr>"
          end
          html += "</table>"
          render html: html.html_safe
        end
        format.json { render json: { connected_devices: devices_info, count: keys.size } }
      end
    end

    private

    def ensure_admin
      unless current_user&.admin?
        render plain: "Forbidden", status: :forbidden
      end
    end

    def fetch_registry_keys
      # Use the public method instead of accessing private instance variables
      Jt808::Registry.connected_devices
    end
  end
end
