class Marketplace::Product < ApplicationRecord
  has_one_attached :image

  validates :name, :price, :category, :target_audience, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }

  scope :active, -> { where(active: true) }
  scope :featured, -> { where(featured: true) }
end
