class Driver < ApplicationRecord
  belongs_to :vehicle
  belongs_to :fleet_provider
end
