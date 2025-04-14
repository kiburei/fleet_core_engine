class Trip < ApplicationRecord
  belongs_to :vehicle
  belongs_to :driver
end
