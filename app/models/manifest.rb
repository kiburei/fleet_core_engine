class Manifest < ApplicationRecord
  belongs_to :trip

  has_many :manifest_items, inverse_of: :manifest, dependent: :destroy

  accepts_nested_attributes_for :manifest_items, allow_destroy: true
end
