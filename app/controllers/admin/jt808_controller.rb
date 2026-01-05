module Admin
  class Jt808Controller < ApplicationController
    before_action :authenticate_user!
    before_action :ensure_admin

    def index
      # Get connected devices
      keys = fetch_registry_keys
      connected_devices_info = keys.map do |key|
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

      # Get all registered devices from DB for comparison
      all_devices = Device.all.map do |device|
        normalized_terminal = normalize_phone(device.terminal_id)
        normalized_sim = normalize_phone(device.sim_number) if device.sim_number.present?
        is_connected = keys.include?(normalized_terminal) || (normalized_sim && keys.include?(normalized_sim))

        {
          device_id: device.id,
          terminal_id: device.terminal_id,
          sim_number: device.sim_number,
          normalized_terminal: normalized_terminal,
          normalized_sim: normalized_sim,
          device_name: device.name,
          status: device.status,
          last_heartbeat_at: device.last_heartbeat_at,
          is_connected: is_connected
        }
      end

      # Check server status
      server_status = check_server_status

      respond_to do |format|
        format.html do
          html = "<h2>JT808 Server Status & Diagnostics</h2>"

          # Server Status
          html += "<h3>Server Status</h3>"
          html += "<table border='1' cellpadding='5' style='margin-bottom: 20px;'>"
          html += "<tr><th>Port</th><th>Status</th><th>Connected Devices</th><th>Server IP Addresses</th></tr>"
          html += "<tr>"
          html += "<td>6808</td>"
          html += "<td>#{server_status[:port_open] ? '✅ Listening' : '❌ Not listening'}</td>"
          html += "<td>#{keys.size}</td>"
          html += "<td>#{server_status[:server_ips].present? ? server_status[:server_ips].join('<br>') : 'Unable to detect'}</td>"
          html += "</tr>"
          html += "</table>"

          if server_status[:server_ips].present?
            html += "<div style='background-color: #fff3cd; padding: 10px; margin-bottom: 20px; border: 1px solid #ffc107;'>"
            html += "<strong>⚠️ Device Configuration Required:</strong><br>"
            html += "Your JT808 device must be configured with:<br>"
            html += "<ul>"
            html += "<li><strong>Server IP:</strong> #{server_status[:server_ips].first} (or one of: #{server_status[:server_ips].join(', ')})</li>"
            html += "<li><strong>Server Port:</strong> 6808</li>"
            html += "</ul>"
            html += "<strong>⚠️ IMPORTANT:</strong> If you see connections from 127.0.0.1 in the logs, the device is configured with localhost instead of the server IP!"
            html += "</div>"
          end

          # Connected Devices
          html += "<h3>Currently Connected Devices (#{keys.size})</h3>"
          if connected_devices_info.empty?
            html += "<p><em>No devices currently connected. Devices will appear here when they connect and send packets.</em></p>"
          else
            html += "<table border='1' cellpadding='5' style='margin-bottom: 20px;'>"
            html += "<tr><th>Registered Phone</th><th>Device ID</th><th>Terminal ID</th><th>SIM Number</th><th>Name</th><th>Status</th><th>Matched By</th></tr>"
            connected_devices_info.each do |info|
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
          end

          # All Registered Devices
          html += "<h3>All Registered Devices in Database (#{all_devices.size})</h3>"
          html += "<table border='1' cellpadding='5' style='margin-bottom: 20px;'>"
          html += "<tr><th>Device ID</th><th>Terminal ID</th><th>SIM Number</th><th>Normalized Terminal</th><th>Normalized SIM</th><th>Name</th><th>Status</th><th>Last Heartbeat</th><th>Connected</th></tr>"
          all_devices.each do |device|
            html += "<tr style='#{device[:is_connected] ? 'background-color: #d4edda;' : 'background-color: #f8d7da;'}'>"
            html += "<td>#{device[:device_id]}</td>"
            html += "<td>#{device[:terminal_id] || 'N/A'}</td>"
            html += "<td>#{device[:sim_number] || 'N/A'}</td>"
            html += "<td>#{device[:normalized_terminal]}</td>"
            html += "<td>#{device[:normalized_sim] || 'N/A'}</td>"
            html += "<td>#{device[:device_name] || 'N/A'}</td>"
            html += "<td>#{device[:status] || 'N/A'}</td>"
            html += "<td>#{device[:last_heartbeat_at] ? device[:last_heartbeat_at].strftime('%Y-%m-%d %H:%M:%S') : 'Never'}</td>"
            html += "<td>#{device[:is_connected] ? '✅ Yes' : '❌ No'}</td>"
            html += "</tr>"
          end
          html += "</table>"

          # Troubleshooting Tips
          html += "<h3>Troubleshooting</h3>"
          html += "<ul>"
          html += "<li><strong>If you see connections from 127.0.0.1 (localhost):</strong>"
          html += "<ul>"
          html += "<li style='color: red;'><strong>⚠️ CRITICAL:</strong> This means your device is configured with localhost/127.0.0.1 instead of the server IP!</li>"
          html += "<li>You MUST configure your device with Server IP = <strong>#{server_status[:server_ips].first || '178.62.101.24'}</strong></li>"
          html += "<li>Port must be set to <strong>6808</strong></li>"
          html += "<li>Check your device configuration via SMS commands or configuration software</li>"
          html += "</ul></li>"
          html += "<li><strong>If no devices are connected:</strong>"
          html += "<ul>"
          html += "<li>Check that your JT808 device is powered on and has network connectivity</li>"
          html += "<li>Verify the device is configured with: Server IP = <strong>#{server_status[:server_ips].first || '178.62.101.24'}</strong>, Port = <strong>6808</strong></li>"
          html += "<li>Check Rails logs for connection attempts (look for 'JT808: New connection from...')</li>"
          html += "<li>Ensure port 6808 is open in your firewall (check with: <code>sudo ufw status</code> or <code>sudo iptables -L</code>)</li>"
          html += "<li>Verify the device's SIM number matches terminal_id or sim_number in the database</li>"
          html += "<li>Test connectivity from device location: <code>telnet #{server_status[:server_ips].first || '178.62.101.24'} 6808</code></li>"
          html += "</ul></li>"
          html += "<li><strong>If device shows in DB but not connected:</strong>"
          html += "<ul>"
          html += "<li>The device must actively connect and send JT808 packets</li>"
          html += "<li>Check that terminal_id or sim_number matches what the device sends (check logs)</li>"
          html += "<li>Normalized phone numbers are used for matching (non-numeric characters removed)</li>"
          html += "<li>Check logs for 'JT808: Parsed packet - phone=...' to see what phone number the device sends</li>"
          html += "</ul></li>"
          html += "</ul>"

          render html: html.html_safe
        end
        format.json do
          render json: {
            server_status: server_status,
            connected_devices: connected_devices_info,
            all_devices: all_devices,
            connected_count: keys.size,
            total_devices: all_devices.size
          }
        end
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

    def normalize_phone(phone)
      phone.to_s.gsub(/[^0-9]/, "")
    end

    def check_server_status
      port_open = false
      begin
        socket = TCPSocket.new("localhost", 6808)
        socket.close
        port_open = true
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
        port_open = false
      rescue => e
        Rails.logger.error "Error checking server status: #{e.message}"
      end

      # Get server's public IP addresses
      server_ips = []
      begin
        # Get all non-loopback IP addresses
        Socket.ip_address_list.each do |addr|
          next if addr.ipv4_loopback? || addr.ipv6_loopback?
          server_ips << addr.ip_address
        end
      rescue => e
        Rails.logger.error "Error getting server IPs: #{e.message}"
      end

      { port_open: port_open, server_ips: server_ips }
    end
  end
end
