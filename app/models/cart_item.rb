class CartItem < ApplicationRecord
  belongs_to :cart

  validates :quantity, presence: true, length: { in: 0..6, message: "%{value} is not between 1 to 5 range" },  on: [:create, :update]
  validates :card_code, presence: {message: "card code is required"}, on: :create
  validates :value, presence: true, numericality: {message: "%{value} is not a numeric value"},  on: :create

  # validates :card_code, :value, absence: true, on: :update
end
