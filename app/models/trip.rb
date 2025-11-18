class Trip < ApplicationRecord
  belongs_to :fleet_provider
  belongs_to :vehicle
  belongs_to :driver

  has_one :manifest, dependent: :destroy

  has_many :gps_points, dependent: :nullify

  accepts_nested_attributes_for :manifest, allow_destroy: true

  status = %w[scheduled in_progress completed cancelled]

  validates :status, presence: true, inclusion: { in: status }
  validates :vehicle, presence: true
  validates :driver, presence: true
  validates :origin, presence: true

  after_initialize :set_default_status, if: :new_record?

  # virtual attribute for form inputs
  attr_accessor :assigned_vehicle, :assigned_driver

  def set_default_status
    self.status ||= "scheduled"
  end

  def scheduled?
    status == "scheduled"
  end

  def in_progress?
    status == "in_progress"
  end

  def completed?
    status == "completed"
  end

  def cancelled?
    status == "cancelled"
  end

  # Accept nested param assignment
  def assigned_vehicle=(attrs)
    self.vehicle_id = attrs[:vehicle_id] if attrs.present?
  end

  def assigned_driver=(attrs)
    self.driver_id = attrs[:driver_id] if attrs.present?
  end
end
