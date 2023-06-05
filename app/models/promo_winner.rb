class PromoWinner < ApplicationRecord
    belongs_to :profile
    belongs_to :promo
    has_one :transaction_log
end
