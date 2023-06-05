FactoryBot.define do
  factory :admin_invite do
    code { "MyString" }
    email { "MyString" }
    role { 1 }
    is_verified { false }
    admin { nil }
  end
end
