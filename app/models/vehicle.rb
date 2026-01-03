class Vehicle < ApplicationRecord
  has_one_attached :logo

  has_one :driver
  has_one :active_device, -> { where(status: :active) }, class_name: "Device"

  belongs_to :vehicle_model
  belongs_to :fleet_provider

  has_many :maintenances, dependent: :destroy
  has_many :incidents
  has_many :trips
  has_many :activities
  has_many :documents, as: :documentable, dependent: :destroy
  has_many :devices
  has_many :gps_points

  def device_online?
    active_device&.online?
  end
end
