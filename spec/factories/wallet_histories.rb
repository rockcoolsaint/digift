FactoryBot.define do
  factory :wallet_history do
    wallet { nil }
    profile { nil }
    sender_details { "" }
    preference { "MyString" }
    type { "" }
    details { "" }
    category { "MyString" }
    amount { 1 }
    balance { 1 }
    commission { 1 }
    actual_amount { 1 }
    description { "MyString" }
    reference_code { "MyString" }
    channel { "MyString" }
    status { false }
    is_active { false }
  end
end
