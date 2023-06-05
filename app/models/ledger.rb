class Ledger < ApplicationRecord
  belongs_to :profile
  belongs_to :vendor
end
