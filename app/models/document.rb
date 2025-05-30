class Document < ApplicationRecord
  belongs_to :documentable, polymorphic: true
  has_one_attached :file

  validates :title, :document_type, presence: true
end
