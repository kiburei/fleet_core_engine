module Jt808
  class Parser
    START_FLAG = "7e"
    END_FLAG   = "7e"

    def self.parse(raw_bytes)
      hex = raw_bytes.unpack1("H*")
      
      # Check start flag
      unless hex[0, 2] == START_FLAG
        Rails.logger.debug "JT808 Parser: Invalid start flag. Expected '7e', got '#{hex[0, 2]}'"
        return nil
      end
      
      # Check end flag
      unless hex[-2, 2] == END_FLAG
        Rails.logger.debug "JT808 Parser: Invalid end flag. Expected '7e', got '#{hex[-2, 2]}'"
        return nil
      end

      # Extract the escaped content (between the frame flags)
      escaped = hex[2..-3]
      return nil if escaped.nil? || escaped.empty?

      # Unescape according to JT808 rules
      content = escaped.gsub("7d02", "7e").gsub("7d01", "7d")

      # Split payload and checksum (checksum is last byte of content)
      if content.length < 2
        Rails.logger.debug "JT808 Parser: Content too short (#{content.length} chars)"
        return nil
      end
      
      checksum_hex = content[-2, 2]
      payload_hex  = content[0...-2]

      # Validate checksum (XOR of all bytes in payload)
      cs = payload_hex.scan(/../).map { |b| b.to_i(16) }.reduce(0) { |a, v| a ^ v }
      calculated_checksum = "%02x" % cs
      unless calculated_checksum == checksum_hex.downcase
        Rails.logger.debug "JT808 Parser: Checksum mismatch. Expected '#{checksum_hex.downcase}', calculated '#{calculated_checksum}'"
        return nil
      end

      # Parse header fields
      message_id = payload_hex[0, 4].to_i(16)
      properties = payload_hex[4, 4].to_i(16)

      phone_bcd = payload_hex[8, 12]
      phone     = decode_bcd(phone_bcd)

      serial = payload_hex[20, 4].to_i(16)

      # Handle package flag (if set, header contains 4 more bytes)
      package_flag = (properties & 0x2000) != 0
      body_start = package_flag ? 32 : 24

      if package_flag
        # total and seq are 2 bytes each (4 hex chars each)
        total = payload_hex[24, 4].to_i(16)
        seq   = payload_hex[28, 4].to_i(16)
      end

      body = payload_hex[body_start..] || ""

      {
        message_id: message_id,
        properties: properties,
        phone: phone,
        serial: serial,
        body_hex: body
      }
    end

    def self.decode_bcd(hex)
      hex.scan(/../).map do |byte|
        val = byte.to_i(16)
        high = (val >> 4) & 0x0f
        low  = val & 0x0f
        "#{high}#{low}"
      end.join.sub(/^0+/, "")
    end
  end
end
