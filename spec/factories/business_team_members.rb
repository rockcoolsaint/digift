FactoryBot.define do
  factory :business_team_member do
    is_active { false }
    Profile { nil }
  end
end
