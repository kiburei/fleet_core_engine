class Incident < ApplicationRecord
  belongs_to :vehicle
  belongs_to :driver, optional: true

  INCIDENT_TYPES = %w[accident breakdown theft other].freeze

  validates :incident_type, inclusion: { in: INCIDENT_TYPES }

  def accident?
    incident_type == "accident"
  end

  def breakdown?
    incident_type == "breakdown"
  end

  def theft?
    incident_type == "theft"
  end

  def other?
    incident_type == "other"
  end
end
