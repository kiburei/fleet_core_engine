require "socket"

Thread.new do
  server = TCPServer.new("0.0.0.0", 6808)
  Rails.logger.info "JT808 GPS Server started on port 6808"

  loop do
    socket = server.accept

    Thread.new(socket) do |client|
      begin
        while raw = client.recv(2048)
          break if raw.empty?

          hex = raw.unpack1("H*")
          Rails.logger.info "Received HEX: #{hex}"

          packet = Jt808::Parser.parse(raw)
          next unless packet

          Jt808::Processor.process(packet, client)
        end
      rescue => e
        Rails.logger.error "JT808 error: #{e.message}"
      ensure
        client.close rescue nil
      end
    end
  end
end
