class Incident < ApplicationRecord
  belongs_to :fleet_provider, optional: true
  belongs_to :vehicle
  belongs_to :driver, optional: true

  has_many :documents, as: :documentable, dependent: :destroy

  INCIDENT_TYPES = %w[accident breakdown theft other].freeze

  validates :incident_type, inclusion: { in: INCIDENT_TYPES }

  # virtual attribute for form inputs
  attr_accessor :assigned_vehicle, :assigned_driver

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

  # Accept nested param assignment
  def assigned_vehicle=(attrs)
    self.vehicle_id = attrs[:vehicle_id] if attrs.present?
  end

  def assigned_driver=(attrs)
    self.driver_id = attrs[:driver_id] if attrs.present?
  end
end
