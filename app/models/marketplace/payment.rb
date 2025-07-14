class Marketplace::Payment < ApplicationRecord
  belongs_to :order
  belongs_to :user

  enum :payment_method, {
    credit_card: 0,
    debit_card: 1,
    bank_transfer: 2,
    mobile_money: 3,
    paypal: 4,
    stripe: 5
  }

  enum :status, {
    pending: 0,
    processing: 1,
    completed: 2,
    failed: 3,
    cancelled: 4,
    refunded: 5
  }

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :payment_method, :status, presence: true
  validates :transaction_id, presence: true, uniqueness: true

  before_validation :generate_transaction_id, on: :create

  scope :successful, -> { where(status: :completed) }
  scope :recent, -> { order(created_at: :desc) }

  def successful?
    completed?
  end

  def can_refund?
    completed? && amount > 0
  end

  private

  def generate_transaction_id
    return if transaction_id.present?
    
    loop do
      self.transaction_id = "TXN-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.hex(6).upcase}"
      break unless self.class.exists?(transaction_id: transaction_id)
    end
  end
end
