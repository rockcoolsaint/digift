FactoryBot.define do
  factory :custom_gift_card do
    __type { "MyString" }
    caption { "MyString" }
    caption_lower { "MyString" }
    code { "MyString" }
    color { "MyString" }
    currency { "MyString" }
    data { "MyString" }
    desc { "MyString" }
    disclosures { "MyString" }
    discount { "9.99" }
    domain { "MyString" }
    fee { "MyString" }
    fontcolor { "MyString" }
    is_variable { false }
    iso { "MyString" }
    logo { "MyString" }
    max_range { "9.99" }
    min_range { "9.99" }
    sendcolor { "MyString" }
    value { "MyString" }
    business { 1 }
    profile { 1 }
    is_active { false }
  end
end
