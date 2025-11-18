module Jt808
  class Parser
    START_FLAG = "7e"
    END_FLAG   = "7e"

    def self.parse(raw_bytes)
      hex = raw_bytes.unpack1("H*")
      return if hex[0, 2] != START_FLAG || hex[-2, 2] != END_FLAG

      # Remove 7e..7e
      content = hex[2..-3]

      # Unescape
      content = content.gsub("7d02", "7e").gsub("7d01", "7d")

      message_id = content[0, 4].to_i(16)
      phone      = content[8, 12] # BCD phone number
      serial     = content[20, 4].to_i(16)
      body       = content[24..]

      {
        message_id: message_id,
        phone:      phone,
        serial:     serial,
        body_hex:   body
      }
    end
  end
end
