class CartSerializer < ActiveModel::Serializer
  attributes :id

  has_many :cart_items

  def cart_items
    cart_items = []
    object.cart_items.map do |cart_item|
      if cart_item.is_active? && !cart_item.is_deleted? && !cart_item.checked_out?
        cart_items << {
          id: cart_item.id,
          cart_id: cart_item.cart_id,
          value: cart_item.value, 
          quantity: cart_item.quantity, 
          card_code: cart_item.card_code
        }
      end
    end
    cart_items
  end
end
