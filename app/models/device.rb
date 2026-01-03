class Device < ApplicationRecord
  belongs_to :vehicle

  def online?
    return true if status == "online"
    return false unless last_heartbeat_at

    last_heartbeat_at > 5.minutes.ago
  end
end
