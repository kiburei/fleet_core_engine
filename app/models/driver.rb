class Driver < ApplicationRecord
  belongs_to :vehicle
  belongs_to :fleet_provider

  has_many :trips
  has_many :incidents
  has_many :documents, as: :documentable, dependent: :destroy

  def full_name
    [ first_name, middle_name, last_name ].compact.join(" ")
  end
end
