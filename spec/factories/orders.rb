FactoryBot.define do
  factory :order do
    card_order_id { "MyString" }
    total_amount { "9.99" }
    amount { "9.99" }
    quantity { 1 }
    gift_card_code { "MyString" }
    details { "" }
    order_type { "MyString" }
    status { "MyString" }
    is_active { false }
    profile { nil }
    transaction_log { nil }
  end
end
