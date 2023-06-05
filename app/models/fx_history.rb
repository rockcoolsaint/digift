class FxHistory < ApplicationRecord
  belongs_to :fx
  belongs_to :admin, optional: true

  # scope :most_recent_updates, -> {}
end
