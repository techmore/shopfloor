class NfcTag < ApplicationRecord
  belongs_to :taggable, polymorphic: true
end
