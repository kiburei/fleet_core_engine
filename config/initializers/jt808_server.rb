require "socket"
require_relative "../../lib/jt808/registry"

Thread.new do
  server = TCPServer.new("0.0.0.0", 6808)
  Rails.logger.info "JT808 GPS Server started on port 6808"

  loop do
    socket = server.accept

    Thread.new(socket) do |client|
      client_ip = client.peeraddr[3] rescue "unknown"
      Rails.logger.info "JT808: New connection from #{client_ip}"
      
      begin
        while raw = client.recv(2048)
          break if raw.empty?

          hex = raw.unpack1("H*")
          Rails.logger.debug "JT808: Received HEX from #{client_ip}: #{hex[0..100]}..." # Log first 100 chars

          packet = Jt808::Parser.parse(raw)
          unless packet
            Rails.logger.warn "JT808: Failed to parse packet from #{client_ip}"
            next
          end

          Rails.logger.info "JT808: Parsed packet - message_id=0x#{packet[:message_id].to_s(16)}, phone=#{packet[:phone]}"

          # Register the socket for this terminal id so we can send commands later
          Jt808::Registry.register(packet[:phone], client)

          Jt808::Processor.process(packet, client)
        end
      rescue => e
        Rails.logger.error "JT808 error from #{client_ip}: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
      ensure
        Rails.logger.info "JT808: Connection closed from #{client_ip}"
        Jt808::Registry.unregister_by_socket(client)
        client.close rescue nil
      end
    end
  end
end
