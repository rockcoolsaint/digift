class Cart < ApplicationRecord
  belongs_to :profile

  has_many :cart_items
end
