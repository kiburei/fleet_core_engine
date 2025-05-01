class FleetProviderUser < ApplicationRecord
  belongs_to :user
  belongs_to :fleet_provider
end
