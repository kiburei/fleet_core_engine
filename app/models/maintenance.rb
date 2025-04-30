class Maintenance < ApplicationRecord
  belongs_to :vehicle
  belongs_to :fleet_provider, optional: true

  has_many :documents, as: :documentable, dependent: :destroy

  valid_mainteance_types = %w[service repair inspection]

  validates :maintenance_type, presence: true, inclusion: { in: valid_mainteance_types }
  validates :maintenance_date, :maintenance_cost, presence: true

  def service?
    maintenance_type == "service"
  end

  def repair?
    maintenance_type == "repair"
  end

  def inspection?
    maintenance_type == "inspection"
  end
end
