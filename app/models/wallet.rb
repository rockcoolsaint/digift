class Wallet < ApplicationRecord
  belongs_to :profile
  belongs_to :business
end
