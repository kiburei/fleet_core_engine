class Vehicle < ApplicationRecord
  belongs_to :vehicle_model
  belongs_to :fleet_provider
end
