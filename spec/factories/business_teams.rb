FactoryBot.define do
  factory :business_team do
    profile { nil }
    business { nil }
    is_active { false }
    team_name { "MyString" }
  end
end
