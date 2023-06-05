FactoryBot.define do
  factory :category do
    title { "MyString" }
    is_active { false }
    category_item_id { 1 }
    admin { nil }
  end
end
