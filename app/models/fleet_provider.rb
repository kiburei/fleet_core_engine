class FleetProvider < ApplicationRecord
  has_many :vehicles, dependent: :destroy
  has_many :drivers, dependent: :destroy
  has_many :trips, dependent: :destroy
  has_many :documents, as: :documentable, dependent: :destroy
  has_many :users, dependent: :destroy
  has_many :maintenance, dependent: :destroy
  has_many :incidents, dependent: :destroy

  resourcify
end
