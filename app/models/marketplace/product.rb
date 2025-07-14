class Marketplace::Product < ApplicationRecord
  belongs_to :user, optional: true
  has_one_attached :image
  has_many :order_items, dependent: :destroy
  has_many :orders, through: :order_items

  validates :name, :price, :category, :target_audience, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }

  scope :active, -> { where(active: true) }
  scope :featured, -> { where(featured: true) }
  scope :by_user, ->(user) { where(user: user) }

  def owned_by?(user)
    self.user == user
  end

  def can_edit?(user)
    return true if user.admin?
    return true if user.service_provider? && owned_by?(user)
    false
  end
end
