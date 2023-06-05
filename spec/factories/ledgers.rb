FactoryBot.define do
  factory :ledger do
    profile { nil }
    vendor { nil }
    debit { "9.99" }
    credit { "9.99" }
    balance { "9.99" }
    is_test { false }
    is_active { false }
  end
end
