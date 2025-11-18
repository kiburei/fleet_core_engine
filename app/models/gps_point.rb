class GpsPoint < ApplicationRecord
  belongs_to :vehicle
  belongs_to :trip, optional: true
end
