class ApplicationController < ActionController::API
  include DeviseTokenAuth::Concerns::SetUserByToken
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :test_transaction_response
  
  # layout :layout_by_resource

  include ExceptionHandler
  include Response
  include SecretKeyHooks

  before_action :authorize_request
  # attr_reader :current_user



  protected
  
    def current_user_by_api_key(api_key=params[:apikey])
      api_key = request.headers['x-auth-apikey'] if !request.headers['x-auth-apikey'].blank?
      api_key = params[:service][:apikey] if params[:service] && params[:service][:apikey]
      api_key = params[:data][:apikey] if params[:data] && params[:data][:apikey]

      raise(ExceptionHandler::InvalidAPIKey, "invalid apikey used!") if api_key.blank?
      
      if api_key.include? "#{business_secret_key_prefix[:test]}"
        @current_user = Business.current_business_by_testKey(api_key)
      elsif api_key.include? "#{business_secret_key_prefix[:live]}"
        @current_user = Business.current_business_by_apiKey(api_key)
      elsif api_key.include? "#{vendor_secret_key_prefix[:test]}"
          @current_user = Vendor.current_vendor_by_testKey(api_key)
      elsif api_key.include? "#{vendor_secret_key_prefix[:live]}"
          @current_user = Vendor.current_vendor_by_liveKey(api_key)
      else
        raise(ExceptionHandler::InvalidAPIKey, "invalid apikey used!")
      end        
    rescue StandardError => e
      raise(ExceptionHandler::InvalidAPIKey, e)
    end


    
    def set_current_business
      begin
        raise ExceptionHandler::InvalidProfileType, 'your profile type is prohibited from this action' unless @current_user.profiles.first.profile_type == 'business'
        @current_business = nil
        my_membership = BusinessTeamMember.find_by!(profile_id: @current_user.profiles.first.id)
        my_team = BusinessTeam.find_by!(id: my_membership.business_team_id)
        @current_business = Business.find_by!(id: my_team.business_id) 

        # if
      rescue Exception => e
        raise ExceptionHandler::InvalidProfileType, e || 'you are prohibited from this action' 
      end
    end


    def validate_business_user_is_admin!
      membership = BusinessTeamMember.where(profile_id: @current_user.profiles.first.id, role: 'admin')
      raise ExceptionHandler::InvalidToken, "you are probihited, you're not an admin" unless membership.exists?
    end
    
    def generate_cashtoken(phone, transaction_log)
    # def generate_cashtoken(phone, amount) #This line is for testing purpose, please it keep for my use
      amount = transaction_log.try(:amount).to_i
      valid_phone = phone_validation(phone)
      if (ENV['CASHTOKEN_PROMO_ACTIVE'] == "true" || ENV['CASHTOKEN_PROMO_ACTIVE'] == true) && amount >= 7000 && !valid_phone.blank?
      # if (ENV['CASHTOKEN_PROMO_ACTIVE'] == "true" || ENV['CASHTOKEN_PROMO_ACTIVE'] == true) && amount.to_i >= 7000 #This line is for testing purpose, please it keep for my use

        case amount
        when 7000 .. 13999
          value = 1
        when 14000 .. 20999
          value = 2
        when 21000 .. 27999
          value = 3
        when 28000 .. 34999
          value = 4
        when 35000 .. 41999
          value = 5
        when 42000 .. 48999
          value = 6
        when 49000 .. 55999
          value = 7
        when 56000 .. 62999
          value = 8
        when 63000 .. 69999
          value = 9
        when amount >= 70000
          value = 10
        end

        payload = {
          "commodity": "cashtoken",
          "batchId": SecureRandom.hex(5),
          "profile": "default",
          "recipients": [
            {
              "recipient": "#{valid_phone}",
              "value": value
            }
          ]
        }

        # payload = {
        #   "commodity": "cashtoken",
        #   "batchId": SecureRandom.hex(5),
        #   "profile": "default",
        #   "campaign": ENV['CASHTOKEN_CAMPAIGN'],
        #   "recipients": [
        #     {
        #       "recipient": phone,
        #       "value": value,
        #       "giftId": "my-unique-gift-id"
        #     }
        #   ]
        # }

        auth = generate_cashtoken_auth_token
        token = JSON.parse(auth).with_indifferent_access[:access_token]
        expires_in = JSON.parse(auth).with_indifferent_access[:expires_in]
        token_payload = token.split('.')[1]
        token_exp = JSON.parse(Base64.decode64(token_payload)).with_indifferent_access[:exp]

        t = Time.now
        res = Concurrent::Future.execute do
          if (t - expires_in) < token_exp
            #make request
            response = RestClient.post(cash_token_base_url,
              payload,
              {
                Authorization: "Bearer " + token, content_type: :json, accept: :json
              }
            )
            # binding.pry
          else
            # generate new token
            token = JSON.parse(generate_cashtoken_auth_token).with_indifferent_access[:access_token]
            # then make request
            response = RestClient.post(cash_token_base_url,
              payload,
              {
                Authorization: "Bearer " + token, content_type: :json, accept: :json
              }
            )

            # binding.pry
          end
        end
        transaction_log.update!(details: transaction_log.details.merge({cashtoken_data: JSON(res.value!).with_indifferent_access[:data]}))
        res.value!
      end
    rescue Exception => e
      raise(ExceptionHandler::RegularError, e)
    end

    def generate_cashtoken_auth_token
      # res = Concurrent::Future.execute do
        auth_payload = "grant_type=client_credentials&scope=#{ENV['CASHTOKEN_SCOPE']}"

        # post request
        # Authorization
        auth_response = RestClient.post(get_cashtoken_access_token_auth_url,
          auth_payload,
          {
            Authorization: "Basic " + Base64::strict_encode64("#{ENV['CASHTOKEN_CLIENT_ID']}:#{ENV['CASHTOKEN_CLIENT_SECRET']}"), content_type: :"application/x-www-form-urlencoded", accept: :json
          }
        )
        auth_response
      # end
      # res.value!
    end

    def cash_token_base_url
      if ENV['RAILS_ENV'] == 'production'
        url = ENV['CASHTOKEN_PRODUCTION_API']
      else
        url = ENV['CASHTOKEN_SANDBOX_API']
      end
    end

    def get_cashtoken_access_token_auth_url
      if ENV['RAILS_ENV'] == 'production'
        url = ENV['CASHTOKEN_PRODUCTION_GET_ACCESS_TOKEN_AUTH_URL']
      else
        url = ENV['CASHTOKEN_SANDBOX_GET_ACCESS_TOKEN_AUTH_URL']
      end
    end

    def phone_validation(phone)
      phone = Phonelib.parse(phone, 'NG')
      if phone.valid?
        return phone.e164('')
      else
        # raise exception
       return false
      end
    end

  protected
  def generate_ref_id
    loop do
      uuid = SecureRandom.uuid
      break uuid unless TransactionLog.find_by(reference_id: uuid)
    end
  end

  # def validate_profile_is_business!
  #   raise ExceptionHandler::RegularError, "your profile is not unauthorized for this action" if @current_user.profiles.first.profile_type != 'business'
  # end

  def validate_personal_user!
    raise(ExceptionHandler::InvalidProfileType, 'your profile is unauthorized for this action') if @current_user.nil? || @current_user.profiles.first.profile_type == 'business'
  end

  def validate_business_user!
    raise(ExceptionHandler::InvalidProfileType, 'your profile is unauthorized for this action') if @current_user.nil? || @current_user.profiles.first.profile_type == 'personal'
  end
    
  private

  def rate
    Fx.get_rate
  end

  def sanitize_with_keys_response(response_list, source)
    response_list.each do |item|
      item[:source] = source
    end
  end

 def sanitize_response(response_list)
    result = []
    response_list.map do |item|
      exampleValues = [100, 200, 500, 1000, 2000, 5000, 10000, 15000, 20000, 50000] 
      data = []
      value = []
      min_range = item.try(:[], "MinimumPrice").to_i
      max_range = exampleValues[(exampleValues.length - 1)]

      fee = ENV["DIGIFTNG_FEE"] || "0"

      code = "sgc_#{item.try(:[], "StoreId")}"

      for amount in exampleValues do
        if amount >= min_range
          data << "#{amount.try(:to_i)}:#{fee}"
          value << amount.try(:to_i)
        end
      end

    
      result << {
            "__type": "item",
            "caption": item.try(:[], "Name"),
            "captionLower": item.try(:[], "Name").downcase,
            "code": code,
            "color": "#0077ff",
            "currency": "NGN",
            "data": "#{code}|#{data.join(",")}|NGN",
            "desc": item.try(:[], "Description"),
            "disclosures": "",
            "discount": 0.0,
            "domain": ENV["WEB_APP_URL"] || "Digiftng.com",
            "fee": "#{fee}",
            "fontcolor": "#FFFFFF",
            "is_variable": item.try(:[], "Visibile") || true,
            "iso": "ng",
            "logo": item.try(:[], "Picture"),
            "max_range": max_range,
            "min_range": min_range,
            "sendcolor": "#FFFFFF",
            "value": value.join(','),
            "source":  ENV["CARD_TYPE_LOCAL"] || "local"
          }
    end
    result
  end




  def total_amount(amount, code='')
    # get total amount of the individual card from data parameter multiplied by the fx_rate
    raise(ExceptionHandler::DataType) if !amount.is_a?(Numeric)
    card_fee = 0.00
    # JSON(@response.body)['d'].each do |card|
    #   if card["code"] == code
    #     card_fee = card["fee"]
    #   end
    # end
    if code.include?("sgc_")
      @fetch_available_gift_card_response[:suregift_response].each do |card|
        if code[4..] === (card["StoreId"]).to_s
          @gift_card_name = card.try(:[], "Name") || card["Name"]
          @gift_card_logo = card.try(:[], "Picture") || card["Picture"]
          @gift_card_min_range = card.try(:[], "MinimumPrice").to_i || card["MinimumPrice"]
          @gift_card_max_range = card.try(:[], "MaximumPrice") || card["MaximumPrice"] || 1000000
          
          card_fee = card["fee"]
        end
      end
      total = (amount.to_d + card_fee.to_d)
    else
      @fetch_available_gift_card_response[:blinksky_response].each do |card|
        if card["code"] == code
          @gift_card_name = card.try(:[], "caption") || card["caption"]
          @gift_card_min_range = card.try(:[], "min_range") || card["min_range"]
          @gift_card_max_range = card.try(:[], "max_range") || card["max_range"]
          @gift_card_logo = card.try(:[], "logo") || card["logo"]
          card_fee = card["fee"]
        end
      end
      total = ((amount.to_d + card_fee.to_d) * rate.to_d)
    end
  end
  def total_amount_multiple(data)
    # get total amount of cards
    total = 0
    if data.length
      data.each do |item|
        card_fee = 0.00
        JSON(@response.body)['d'].each do |card|
          if card["code"] == (item[:code] || item[:card_code])
            @gift_card_name = card.try(:[], "caption") || card["caption"]
            card_fee = card["fee"]
          end
        end
        raise(ExceptionHandler::DataType) if !item[:value].to_d.is_a?(Numeric)
        total += ((item[:value].to_d + card_fee.to_d) * item[:quantity].to_i)
      end
    end
    total * rate.to_d
  end
  # Check for valid request token and return user
  def authorize_request
    #@current_user = (AuthorizeApiRequest.new(request.headers).call)[:user]
    @current_user = current_user unless @current_user
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_in, keys: [:email, :password])
  end

  def layout_by_resource
    if devise_controller?
      "devise"
    else
      "application"
    end
  end
  def test_transaction_response
    response_file = File.join(Rails.root, 'app', 'test_files', 'response.json')
    file = File.read(response_file)
    @data_hash = JSON.parse(file)
  end
  def transaction_fail(data, service_type)
    if @transaction_log.try(:exists?) && @transaction_log.exists?
      @transaction_log.update!(details: @transaction_log.details.merge({data: data, payload: @payload}), gift_card_name: service_type)
      @transaction_log.failed!
    end
  end
end
