module Jt808
  class Registry
    @mutex = Mutex.new
    @map = {}

    def self.normalize(id)
      id.to_s.gsub(/[^0-9]/, "")
    end

    def self.register(terminal_id, socket)
      return unless terminal_id && socket
      key = normalize(terminal_id)
      @mutex.synchronize do
        @map[key] = socket
      end
      Rails.logger.info "JT808: registered socket for terminal=#{key}"
    end

    def self.unregister_by_socket(socket)
      @mutex.synchronize do
        @map.delete_if { |_, s| s == socket }
      end
    end

    def self.get_socket(terminal_id)
      key = normalize(terminal_id)
      @mutex.synchronize { @map[key] }
    end
  end
end
