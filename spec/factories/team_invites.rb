FactoryBot.define do
  factory :team_invite do
    code { "MyString" }
    email { "MyString" }
    role { "MyString" }
    business { nil }
    business_team { nil }
  end
end
