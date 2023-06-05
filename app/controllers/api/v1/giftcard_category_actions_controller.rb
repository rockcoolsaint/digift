class Api::V1::GiftcardCategoryActionsController < ApplicationController
    before_action :authenticate_user!, only: []


    
    def index

        @categories = []
        Category.find_each do |card|
          @categories << card if card.try(:is_active)
        end
    
        json_response({
          status: 200,
          data: { :categories=> ActiveModelSerializers::SerializableResource.new(@categories, each_serializer: WebGiftCardsCategorySerializer) },
          message: "All available Gift Card categories",
          errMessage: nil
        })
      end
end
