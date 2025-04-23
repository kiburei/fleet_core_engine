class Vehicle < ApplicationRecord
  has_one :driver

  belongs_to :vehicle_model
  belongs_to :fleet_provider

  has_many :maintenances, dependent: :destroy
  has_many :incidents
  has_many :activities
end
