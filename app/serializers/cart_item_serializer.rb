class CartItemSerializer < ActiveModel::Serializer
  attributes :id, :cart_id, :value, :quantity, :card_code

  # belongs_to :cart
end
