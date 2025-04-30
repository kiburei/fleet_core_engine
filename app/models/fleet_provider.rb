class FleetProvider < ApplicationRecord
  has_many :vehicles, dependent: :destroy
  has_many :drivers, dependent: :destroy
  has_many :trips, dependent: :destroy
  has_many :documents, as: :documentable, dependent: :destroy
  has_many :users, dependent: :destroy

  resourcify
end
