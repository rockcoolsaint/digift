FactoryBot.define do
  factory :cart do
    id { "" }
    profile { nil }
    checked_out { false }
    is_active { false }
  end
end
