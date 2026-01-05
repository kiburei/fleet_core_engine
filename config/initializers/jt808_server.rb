require "socket"
require_relative "../../lib/jt808/registry"

Thread.new do
  server = TCPServer.new("0.0.0.0", 6808)
  Rails.logger.info "JT808 GPS Server started on port 6808"

  loop do
    socket = server.accept

    Thread.new(socket) do |client|
      begin
        peer_info = client.peeraddr
        client_ip = peer_info[3]
        client_port = peer_info[1]
        client_hostname = peer_info[2] rescue "unknown"
      rescue => e
        client_ip = "unknown"
        client_port = "unknown"
        client_hostname = "unknown"
      end
      
      Rails.logger.info "JT808: New connection from #{client_ip}:#{client_port} (#{client_hostname})"
      
      # Warn if connection is from localhost - device might be misconfigured
      if client_ip == "127.0.0.1" || client_ip == "::1" || client_ip == "localhost"
        Rails.logger.warn "JT808: WARNING - Connection from localhost (#{client_ip})!"
        Rails.logger.warn "JT808: This usually means the device is configured with localhost/127.0.0.1 instead of the server IP"
        Rails.logger.warn "JT808: Device should be configured with server IP: #{Socket.ip_address_list.find { |ip| !ip.ipv4_loopback? && !ip.ipv6_loopback? }&.ip_address || 'YOUR_SERVER_IP'}"
      end
      
      begin
        # Set TCP_NODELAY for lower latency
        client.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
        
        data_received = false
        loop do
          raw = client.recv(2048)
          
          if raw.nil? || raw.empty?
            Rails.logger.warn "JT808: Received empty/nil data from #{client_ip}, closing connection"
            break
          end
          
          data_received = true
          hex = raw.unpack1("H*")
          Rails.logger.info "JT808: Received #{raw.length} bytes from #{client_ip}"
          Rails.logger.info "JT808: HEX data: #{hex}"

          packet = Jt808::Parser.parse(raw)
          unless packet
            Rails.logger.warn "JT808: Failed to parse packet from #{client_ip}"
            Rails.logger.warn "JT808: Raw HEX (first 100 chars): #{hex[0..100]}"
            Rails.logger.warn "JT808: Raw HEX (last 100 chars): #{hex[-100..-1]}" if hex.length > 100
            # Continue listening for more packets - don't break the connection
            next
          end

          Rails.logger.info "JT808: Successfully parsed packet - message_id=0x#{packet[:message_id].to_s(16)}, phone=#{packet[:phone]}, serial=#{packet[:serial]}"

          # Register the socket for this terminal id so we can send commands later
          Jt808::Registry.register(packet[:phone], client)

          Jt808::Processor.process(packet, client)
        end
        
        unless data_received
          Rails.logger.warn "JT808: Connection from #{client_ip} closed without receiving any data"
        end
      rescue => e
        Rails.logger.error "JT808 error from #{client_ip}: #{e.class.name}: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
      ensure
        Rails.logger.info "JT808: Connection closed from #{client_ip}"
        Jt808::Registry.unregister_by_socket(client)
        client.close rescue nil
      end
    end
  end
end
