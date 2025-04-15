class FleetProvider < ApplicationRecord
  has_many :vehicles, dependent: :destroy
  has_many :drivers, dependent: :destroy
  has_many :trips, dependent: :destroy
end
