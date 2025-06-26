class VehicleModel < ApplicationRecord
  def name
    "#{make} #{model}"
  end

  def to_s
    name
  end
end
