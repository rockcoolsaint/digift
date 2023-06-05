class TransactionLogSerializer < ActiveModel::Serializer
    # attributes to be serialized  
    attributes :id, :profile_id, :log_type, :status, :reference_id, :amount, :gift_card_code, :gift_card_name, :transaction_rate, :created_at, :updated_at
     # model association
    has_many :orders
    def orders
      object.orders.map do |order|
        {
          id: order.id,
          card_order_id: order.card_order_id,
          amount: order.amount,
          total_amount: order.total_amount,
          quantity: order.quantity,
          gift_card_code: order.gift_card_code,
          order_type: order.order_type,
          status: order.status,
          created_at: order.created_at,
          updated_at: order.updated_at
        }
      end
    end
end
