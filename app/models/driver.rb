class Driver < ApplicationRecord
  belongs_to :vehicle
  belongs_to :fleet_provider

  has_many :trips
  has_many :incidents

  def full_name
    [ first_name, middle_name, last_name ].compact.join(" ")
  end
end
