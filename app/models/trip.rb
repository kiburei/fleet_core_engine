class Trip < ApplicationRecord
  belongs_to :fleet_provider
  belongs_to :vehicle
  belongs_to :driver
end
