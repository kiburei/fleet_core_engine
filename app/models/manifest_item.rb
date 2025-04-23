class ManifestItem < ApplicationRecord
  belongs_to :manifest

  item_type = %w[passenger cargo crew]

  validates :item_type, presence: true, inclusion: { in: item_type }

  def passenger?
    item_type == "passenger"
  end

  def cargo?
    item_type == "cargo"
  end

  def crew?
    item_type == "crew"
  end
end
