class Api::V1::AdminCategoryActionsController < ApplicationController
  before_action :authenticate_admin!
  before_action :set_category, only: [:update]

  def index

    @categories = []
    Category.find_each do |card|
      @categories << card
    end

    json_response({
      status: 200,
      data: { :categories=> ActiveModelSerializers::SerializableResource.new(@categories, each_serializer: AdminGiftCardsCategorySerializer) },
      message: "all available categories",
      errMessage: nil
    })
  end


  def create
    # binding.pry
    @category = Category.create!(
      title: category_params[:title],
      admin: current_admin
    )
  
    json_response({
      status: 201,
      data: { :category=> ActiveModelSerializers::SerializableResource.new(@category, each_serializer: AdminGiftCardsCategorySerializer)},
      message: "category created",
      errMessage: nil
    })
  rescue => e
    raise(ExceptionHandler::RegularError, e)
  end

  def update
    @category.update!(category_params)

    json_response({
      status: 201,
      data: { :category=> ActiveModelSerializers::SerializableResource.new(@category, each_serializer: AdminGiftCardsCategorySerializer) },
      message: "category updated",
      errMessage: nil
    })
  rescue => e
    raise(ExceptionHandler::RegularError, e)
  end

  private
  def category_params
    params.require(:data).permit(:title, :is_active)
  end

  def set_category
    @category = Category.find(params[:id])
  end
end
