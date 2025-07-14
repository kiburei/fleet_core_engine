class Marketplace::Order < ApplicationRecord
  belongs_to :user
  has_many :order_items, dependent: :destroy
  has_many :products, through: :order_items
  has_many :payments, dependent: :destroy

  enum :status, {
    pending: 0,
    processing: 1,
    shipped: 2,
    delivered: 3,
    cancelled: 4,
    refunded: 5
  }

  enum :payment_status, {
    unpaid: 0,
    paid: 1,
    partially_paid: 2,
    payment_refunded: 3
  }

  validates :order_number, presence: true, uniqueness: true
  validates :total_amount, presence: true, numericality: { greater_than: 0 }
  validates :status, :payment_status, presence: true

  before_validation :generate_order_number, on: :create

  scope :recent, -> { order(created_at: :desc) }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_payment_status, ->(payment_status) { where(payment_status: payment_status) }

  def total_items
    order_items.sum(:quantity)
  end

  def can_cancel?
    pending? || processing?
  end

  def can_refund?
    paid? && (delivered? || cancelled?)
  end

  def provider_orders
    # Group order items by service provider
    order_items.includes(:product).group_by { |item| item.product.user }
  end

  private

  def generate_order_number
    return if order_number.present?
    
    loop do
      self.order_number = "ORD-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.hex(4).upcase}"
      break unless self.class.exists?(order_number: order_number)
    end
  end
end
