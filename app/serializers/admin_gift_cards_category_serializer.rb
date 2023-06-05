
class AdminGiftCardsCategorySerializer < ActiveModel::Serializer
  attributes :id, :title, :is_active

  has_many :category_items, key: :items, serializer: AdminGiftCardsCategoryItemSerializer
  belongs_to :admin, key: :created_by, serializer: AdminGiftCardsCategoryItemAdminSerializer
  
  def created_by
    object.created_by.email
  end

  # def items
  #   object.category_items.select do |item|
  #     if item.try(:[], :is_active)
  #       item
  #     end
  #   end
  # end
end
