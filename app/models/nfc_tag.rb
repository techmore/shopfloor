class NfcTag < ApplicationRecord
  belongs_to :taggable, polymorphic: true, optional: true
  belongs_to :written_by, class_name: "User", optional: true, inverse_of: :nfc_tags
  has_many :shipments, dependent: :restrict_with_error

  validates :tag_uid, presence: true, uniqueness: { case_sensitive: false }

  before_validation { self.tag_uid = tag_uid.to_s.strip.upcase.presence }
end
