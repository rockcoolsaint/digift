class AdminTransactionsSerializer < ActiveModel::Serializer
    # attributes to be serialized  
    attributes :id, :profile_id, :log_type, :status, :payment_reference, :gift_card_code, :gift_card_name, :customer, :transaction_reference, :amount, :transaction_rate, :created_at, :updated_at
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
    def payment_reference
      object.reference_id
    end

    def transaction_reference
      object.id
    end

    def customer
      object.profile.user.email
      
    end
end
