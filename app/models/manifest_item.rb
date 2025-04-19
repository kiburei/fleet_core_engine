class ManifestItem < ApplicationRecord
  belongs_to :manifest

  item_type = %w[passenger cargo]

  validates :item_type, presence: true, inclusion: { in: item_type }

  def passenger?
    item_type == "passenger"
  end

  def cargo?
    item_type == "cargo"
  end
end
