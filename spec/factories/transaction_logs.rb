FactoryBot.define do
  factory :transaction_log do
    profile { nil }
    wallet { nil }
    wallet_history { nil }
    gift_card_code { "MyString" }
    details { "" }
    log_type { 1 }
    status { 1 }
    is_active { false }
    reference_id { "" }
    amount { "9.99" }
    transaction_rate { "" }
  end
end
