module Jt808
  class Decoders
    def self.decode_location(body_hex)
      alarm     = body_hex[0, 8].to_i(16)
      status    = body_hex[8, 8].to_i(16)
      lat       = body_hex[16, 8].to_i(16) / 1_000_000.0
      lng       = body_hex[24, 8].to_i(16) / 1_000_000.0
      altitude  = body_hex[32, 4].to_i(16)
      speed     = body_hex[36, 4].to_i(16) / 10.0
      direction = body_hex[40, 4].to_i(16)

      time_hex = body_hex[44, 12]
      timestamp = Time.strptime(time_hex, "%y%m%d%H%M%S")

      {
        lat: lat,
        lng: lng,
        speed: speed,
        direction: direction,
        timestamp: timestamp
      }
    end
  end
end
