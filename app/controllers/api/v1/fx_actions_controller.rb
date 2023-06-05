class Api::V1::FxActionsController < ApplicationController
  # before_action :authenticate_user!, only: [:index]
  # before_action :validate_business_user!, only: [:index]
  before_action :current_user_by_api_key, only: [:index]

  def index
    fx_rate = []
    Fx.find_each do |fx|
      fx_rate << fx
    end

    json_response({
      status: 200,
      data: {
        fx_rate: ActiveModelSerializers::SerializableResource.new(fx_rate, each_serializer: FxrateSerializer)  
      },
      message: "current fx_rate on the platform",
      errMessage: nil
    })
  end



  def get_web_rates
    fx_rate = []
    Fx.find_each do |fx|
      fx_rate << fx if fx.is_active? && fx.is_public?
    end

    json_response({
      status: 200,
      data: {
        fx_rate: ActiveModelSerializers::SerializableResource.new(fx_rate, each_serializer: FxrateSerializer) 
      },
      message: "current fx_rate on the platform",
      errMessage: nil
    })
  end

  # def fetch_fx_history
  # end
end