class Api::V1::CustomGiftCardActionsController < ApplicationController
  before_action :validate_business_user!, except: [:index]
  before_action :set_card, only: [:update]
  before_action :set_current_business, only: [:create, :show]
  before_action :validate_business_user_is_admin!, except: [:index]
  
  

  
  def index
    begin
      @custom_cards = []
      CustomGiftCard.find_each do |card|
        @custom_cards << card if card.try(:is_active) && !card.try(:is_disabled)
      end

      if !params[:per_page].blank?
        @custom_cards = Kaminari.paginate_array(@custom_cards.sort!{ |a,b|   a.caption <=> b.caption }).page(params[:page]).per(params[:per_page])
      else
        @custom_cards = Kaminari.paginate_array(@custom_cards.sort!{ |a,b|   a.caption <=> b.caption }).page(params[:page])
      end

      total = @custom_cards.total_count
      page_count = @custom_cards.total_pages  
      per_page = @custom_cards.limit_value 
      current_page = @custom_cards.current_page
      next_page = @custom_cards.next_page
      prev_page = @custom_cards.prev_page
      first_page = @custom_cards.first_page?
      last_page = @custom_cards.last_page?

    
  
      json_response({
        status: 200,
        data: {
          total: total,
          page_count: page_count,
          per_page: per_page,
          current_page: current_page,
          next_page: next_page,
          prev_page: prev_page,
          first_page: first_page,
          last_page: last_page,
          data: ActiveModelSerializers::SerializableResource.new(@custom_cards, each_serializer: CustomGiftCardSerializer)
        },
        message: "available gift cards",
        errMessage: nil
      })
    rescue Exception => e
      raise(ExceptionHandler::RegularError, e)
    end
   
  end

  def create
    begin
      
      unless params.try(:[], :data) && params.try(:[], :data).try(:[], :values)
        raise(ExceptionHandler::RegularError, 'Please provided values field') 
      end
    values = params[:data][:values]

    if values.kind_of?(String)
      values = JSON.parse(params[:data][:values])
    end
      @custom_card = CustomGiftCard.create!(
        caption: custom_card_params[:caption],
        color: custom_card_params[:color],
        desc: custom_card_params[:desc],
        disclosures: custom_card_params[:disclosures],
        discount: custom_card_params[:discount],
        fontcolor: custom_card_params[:fontcolor],
        max_range: custom_card_params[:max_range],
        min_range: custom_card_params[:min_range],
        logo: custom_card_params[:logo],
        values: values,
        profile: @current_user.profiles.first,
        business: @current_business,
        domain: ENV["WEB_APP_URL"],
        is_disabled: custom_card_params[:is_disabled] || false
      )
      
      CustomGiftCard.find(@custom_card.id).update!(code: "dcg_#{@custom_card.id}")
      json_response({
        status: 200,
        data: nil,
        message: "created gift card",
        errMessage: nil
      })
    rescue => e
      raise(ExceptionHandler::RegularError, e)
    end
  end

  def show
    @custom_cards = []
    begin
      CustomGiftCard.find_each do |card|
        if @current_business.id == card.try(:business_id)
          @custom_cards << card if card.try(:is_active) == true && card.try(:is_disabled) != true
        end
      end
    
      if !params[:per_page].blank?
        @custom_cards = Kaminari.paginate_array(@custom_cards.sort!{ |a,b|   b.created_at <=> a.created_at }).page(params[:page]).per(params[:per_page])
      else
        @custom_cards = Kaminari.paginate_array(@custom_cards.sort!{ |a,b|   b.created_at <=> a.created_at }).page(params[:page])
      end

      total =  @custom_cards.total_count
      page_count =  @custom_cards.total_pages  
      per_page =  @custom_cards.limit_value 
      current_page =  @custom_cards.current_page
      next_page =  @custom_cards.next_page
      prev_page =  @custom_cards.prev_page
      first_page =  @custom_cards.first_page?
      last_page =  @custom_cards.last_page?


      response.headers['total'] = total
      response.headers['page_count'] = page_count
      response.headers['per_page'] = per_page
      response.headers['current_page'] = current_page
      response.headers['next_page'] = next_page
      response.headers['prev_page'] = prev_page
      response.headers['first_page'] = first_page
      response.headers['last_page'] = last_page
      
      json_response({
        status: 200,
        data: {
          total: total,
          page_count: page_count,
          per_page: per_page,
          current_page: current_page,
          next_page: next_page,
          prev_page: prev_page,
          first_page: first_page,
          last_page: last_page,
          data: ActiveModelSerializers::SerializableResource.new(@custom_cards, each_serializer: CustomGiftCardSerializer)
        },
        message: "all transatcions",
        errMessage: nil
      })
    rescue Exception => e
      raise ExceptionHandler::RegularError, e
    end

  end

  def update
    begin

      values = nil
      values = params[:data][:values] if params.try(:[], :data) && params.try(:[], :data).try(:[], :values)
      if !values.nil? && values.kind_of?(String)
        values = JSON.parse(params[:data][:values])
      end
      @custom_card.update!(custom_card_params)

      if params.try(:[], :data) && params.try(:[], :data).try(:[], :values)
        @custom_card.update!({values: values})
      end
     
      json_response({
        status: 200,
        data: nil,
        message: "gift card updated",
        errMessage: nil
      })
    rescue => e
      raise ExceptionHandler::RegularError, e
    end

  end

  private
  def custom_card_params
    # whitelist params
    params.require(:data).permit(
      :caption,
      :color,
      :desc,
      :disclosures,
      :discount,
      :fontcolor,
      :max_range,
      :min_range,
      :logo,
      :is_disabled
    )
  end

  def set_card
    unless params[:code].blank?
      if params[:code].include?("dcg")
        @custom_card = CustomGiftCard.find_by(code: params[:code])
      else
        @custom_card = CustomGiftCard.find(params[:code])
      end
    end
  end
end
