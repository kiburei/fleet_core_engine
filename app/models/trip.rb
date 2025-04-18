class Trip < ApplicationRecord
  belongs_to :fleet_provider
  belongs_to :vehicle
  belongs_to :driver

  has_one :manifest, dependent: :destroy

  accepts_nested_attributes_for :manifest, allow_destroy: true
end
