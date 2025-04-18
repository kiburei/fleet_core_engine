class Manifest < ApplicationRecord
  belongs_to :trip

  has_many :manifest_items, dependent: :destroy

  accepts_nested_attributes_for :manifest_items, allow_destroy: true
end
