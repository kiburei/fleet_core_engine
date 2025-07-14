class Marketplace::OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :unit_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :total_price, presence: true, numericality: { greater_than_or_equal_to: 0 }

  before_save :calculate_total_price

  def service_provider
    product.user
  end

  private

  def calculate_total_price
    self.total_price = quantity * unit_price
  end
end
