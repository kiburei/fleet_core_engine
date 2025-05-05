class Driver < ApplicationRecord
  has_one_attached :profile_picture

  belongs_to :vehicle, optional: true
  belongs_to :fleet_provider

  has_many :trips
  has_many :incidents
  has_many :documents, as: :documentable, dependent: :destroy

  def full_name
    [ first_name, middle_name, last_name ].compact.join(" ")
  end
end
