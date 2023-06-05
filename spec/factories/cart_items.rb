FactoryBot.define do
  factory :cart_item do
    cart { nil }
    amount { "9.99" }
    is_active { false }
    quantity { "9.99" }
    card_code { "MyString" }
    checked_out { false }
    is_deleted { false }
  end
end
