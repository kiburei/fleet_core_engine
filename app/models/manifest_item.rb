class ManifestItem < ApplicationRecord
  belongs_to :manifest

  enum item_type: { passenger: "passenger", goods: "goods", crew: "crew" }
end
