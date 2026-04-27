class Device < ApplicationRecord
  belongs_to :vehicle

  scope :with_traccar, -> { where.not(traccar_id: nil) }
  validates :traccar_id, uniqueness: true, allow_nil: true

  def online?
    return true if status == "online"
    return false unless last_heartbeat_at

    last_heartbeat_at > 5.minutes.ago
  end
end
