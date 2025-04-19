class Trip < ApplicationRecord
  belongs_to :fleet_provider
  belongs_to :vehicle
  belongs_to :driver

  has_one :manifest, dependent: :destroy

  accepts_nested_attributes_for :manifest, allow_destroy: true

  status = %w[scheduled in_progress completed cancelled]

  validates :status, presence: true, inclusion: { in: status }

  after_initialize :set_default_status, if: :new_record?

  def set_default_status
    self.status ||= "scheduled"
  end

  def scheduled?
    status == "scheduled"
  end

  def in_progress?
    status == "in_progress"
  end

  def completed?
    status == "completed"
  end

  def cancelled?
    status == "cancelled"
  end
end
