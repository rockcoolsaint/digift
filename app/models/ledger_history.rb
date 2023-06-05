class LedgerHistory < ApplicationRecord
  belongs_to :ledger
  belongs_to :vendor
  belongs_to :profile
end
