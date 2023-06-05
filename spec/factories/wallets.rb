FactoryBot.define do
  factory :wallet do
    profile { nil }
    cleared_balance { 1 }
    available_balance { 1 }
    is_active { false }
    profile_type { "MyString" }
  end
end
