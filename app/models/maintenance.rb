class Maintenance < ApplicationRecord
  belongs_to :vehicle

  VALID_MAINTENANCE_TYPES = %w[service repair inspection]

  validates :maintenance_type, presence: true, inclusion: { in: VALID_MAINTENANCE_TYPES }
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
