class Api::V1::AdminCategoryItemActionsController < ApplicationController
  before_action :authenticate_admin!
  before_action :set_category_item, only: [:update]
  


  
  def create
    @category_item = CategoryItem.create!(category_item_params)
   
    json_response({
      status: 201,
      data: { :category_item => ActiveModelSerializers::SerializableResource.new(@category_item, each_serializer: AdminGiftCardsCategoryItemSerializer)},
      message: "category item created",
      errMessage: nil
    })
  rescue => e
    raise(ExceptionHandler::RegularError, e)
  end

  def update
    @category_item.update!(is_active: category_item_params[:is_active])

    json_response({
      status: 201,
      data: { :category_item => ActiveModelSerializers::SerializableResource.new(@category_item, each_serializer: AdminGiftCardsCategoryItemSerializer)},
      message: "category item updated",
      errMessage: nil
    })
  rescue => e
    raise(ExceptionHandler::RegularError, e)
  end

  private
  def category_item_params
    params.require(:data).permit(:item_id, :category_id, :is_active, :item_name)
  end

  def set_category_item
    @category_item = CategoryItem.find(params[:id])
  end
end
