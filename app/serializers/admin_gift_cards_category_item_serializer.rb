class AdminGiftCardsCategoryItemSerializer < ActiveModel::Serializer
  attributes :id, :caption, :code, :is_active


  def code
    object.item_id
  end
  def caption
    object.item_name
  end
end
