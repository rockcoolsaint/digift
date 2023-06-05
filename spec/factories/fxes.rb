FactoryBot.define do
  factory :fx do
    name { "MyString" }
    currency { "MyString" }
    currency_symbol { "MyString" }
    iso { "MyString" }
    rate { "9.99" }
    is_active { false }
  end
end
