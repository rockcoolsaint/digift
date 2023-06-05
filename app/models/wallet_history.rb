class WalletHistory < ApplicationRecord
  belongs_to :wallet
  belongs_to :profile
end
