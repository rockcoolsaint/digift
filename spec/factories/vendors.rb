FactoryBot.define do
  factory :vendor do
    business_name { "MyString" }
    references { "" }
    industry { "MyString" }
    registration_status { "MyString" }
    country_of_incorporation { "MyString" }
    is_live { false }
    live_key { "MyString" }
    test_key { "MyString" }
  end
end
