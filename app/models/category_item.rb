class CategoryItem < ApplicationRecord
    belongs_to :category


    validates_presence_of :item_id, :item_name, :category_id, on: :create
end
