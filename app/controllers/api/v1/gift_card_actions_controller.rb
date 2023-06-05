class Api::V1::GiftCardActionsController < ApplicationController
  # skip_before_action :verify_authenticity_token
  # before_action :user_signed_in?, except: [:index]
  before_action :authenticate_user!, only: [:send_retail_card]
  before_action :fetch_harmonized_available_gift_card, only: [:index, :fetch]
  before_action :fetch_available_gift_card, only: [:send_card, :vendor_send_card, :send_retail_card, :send_retail_cards_for_cart]
  before_action :current_user_by_api_key, except: [:fetch, :send_retail_card, :send_tmp_retail_card, :send_retail_cards_for_cart]
  skip_before_action :authorize_request, only: [:send_tmp_retail_card]


  def index
    begin
      profile_type = @current_user.profiles.first.profile_type
      if profile_type == "vendor"
        vendor = Vendor.find_by(profile: @current_user.profiles.first.id)
        if vendor.is_authorised
          vendor_allowed_giftcard_sources = VendorAllowedGiftcardSource.find_by!({vendor_id: vendor.id})
          @harmonized_response =  @harmonized_response.select{ |item| vendor_allowed_giftcard_sources.sources.include?(item.with_indifferent_access[:source]) }
          json_response({
            status: 200,
            data: @harmonized_response,
            message: "Available gift cards",
            errMessage: nil
            })
        else
          json_response({
            status: 200,
            data: [],
            message: "no giftcards associated with this account, please contact support for assistance",
            errMessage: nil
            })
        end
        
      else
        json_response({
          status: 200,
          data: @harmonized_response,
          message: "Available gift cards",
          errMessage: nil
          })
      end
     
    rescue => e
      json_response({
        status: 500,
        data: nil,
        message: "Error",
        errMessage: e.message || "Oops, can't fetch giftcards at this time"
        }, :internal_server_error)
    end
   
  end


  def fetch
   # if ENV["RAILS_ENV"] == "production"
    #   if ENV["WEB_APP_URL"].include? request.host
    #     index
    #   elsif request.host == 'localhost'
    #     index
    #   else
    #      json_response({
    #        status: 401,
    #        data: nil,
    #        message: "Error",
    #        errMessage: "This route is prohibited"
    #         }, :unauthorized)
    #   end
    #   return
    # end
    begin
      per = 25
      filtered_harmonized_response = SearchAvailableGiftcardsService.new(@harmonized_response, params[:q], params[:min_price], params[:max_price], params[:category]).call
        
      if filtered_harmonized_response.empty?
        @harmonized_response = Kaminari.paginate_array(filtered_harmonized_response).page(params[:page])
        total = @harmonized_response.total_count
        page_count = @harmonized_response.total_pages
        per_page = @harmonized_response.limit_value
        current_page = @harmonized_response.current_page
        next_page = @harmonized_response.next_page
        prev_page = @harmonized_response.prev_page
        first_page = @harmonized_response.first_page?
        last_page = @harmonized_response.last_page?

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
            data: []
          },
          message: "Sorry, your search doesn't match any item(s)",
          errMessage: nil
          })
        return
      end

        per = filtered_harmonized_response.try(:length) 
        per = params[:per_page] unless params[:per_page].blank?


        
        @harmonized_response = Kaminari.paginate_array(filtered_harmonized_response).page(params[:page]).per(per)
        total = @harmonized_response.total_count
        page_count = @harmonized_response.total_pages
        per_page = @harmonized_response.limit_value
        current_page = @harmonized_response.current_page
        next_page = @harmonized_response.next_page
        prev_page = @harmonized_response.prev_page
        first_page = @harmonized_response.first_page?
        last_page = @harmonized_response.last_page?

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
            data: @harmonized_response
          },
          message: "available gift cards",
          errMessage: nil
          })
      # end
    rescue => e
      json_response({
        status: 500,
        data: nil,
        message: "Error",
        errMessage: e.message || "Oops, can't fetch giftcards at this time"
        }, :internal_server_error)
    end
  end

  def send_card
    begin
      # if in test mode, do something in test mode
      data = params[:data]
      if ENV['TEST_MODE'] == "true" || ENV['TEST_MODE'] == true
        test_response

       # APIKey validation
      elsif request.headers['x-auth-apikey'].include?(business_secret_key_prefix[:live]) || data[:apikey].include?(business_secret_key_prefix[:live])
        # if current_business.is_live?
          @wallet = Wallet.find_by!(profile_id: @current_user.profiles.first.id, is_test: false)
          # if  live and wallet is active
          # Wallet validation
          errors = ValidateNewTransaction.new(
            current_user: @current_user,
            amount: total_amount(data[:card][:amount], data[:card][:code]),
            transaction_type: 'send',
            wallet: @wallet,
            transaction_log: nil,
          ).execute!
          if errors.count > 0
            json_response({
              status: 422,
              data: nil,
              message: "Error",
              errMessage: errors[0]
            }, :unprocessable_entity)
          elsif @wallet.is_active? # check that the wallet is active
            card_response = PerformTransaction.new(
              current_user: @current_user,
              transaction_type: "send",
              wallet: @wallet,
              data: params[:data].to_unsafe_h,
              total_amount: total_amount(data[:card][:amount], data[:card][:code]),
              gift_card_name: @gift_card_name
            ).execute!

            result = card_response.length ? card_response[0] : card_response

            json_response({
              status: 200,
              data: result,
              message: "success",
              errMessage: nil
              })
          else
            json_response({
              status: 402,
              data: nil,
              message: 'Error',
              errMessage: "Your wallet is inactive. Please fund your wallet to activate, before proceeding."}, :payment_required)
          end
  
    
      else
        
        # APIKey validation
        @wallet = Wallet.find_by!(profile_id: @current_user.profiles.first.id, is_test: true)
        # if test and wallet is active
        # Wallet validation
        errors = ValidateNewTransaction.new(
          current_user: @current_user,
          amount: total_amount(data[:card][:amount], data[:card][:code]),
          transaction_type: 'send',
          wallet: @wallet
        ).execute!
        if errors.count > 0
          json_response({
            status: 422,
            data: nil,
            message: "Error",
            errMessage: errors[0]
          }, :unprocessable_entity)

        elsif @wallet.is_active? # check that the wallet is active

          wallet_history = create_wallet_history(@wallet, 'send', data[:card][:dest],data[:card][:amount], 'gift_card', total_amount(data[:card][:amount], data[:card][:code]))
          transaction_log = create_transaction_log(@wallet, wallet_history, 'send', 'test', data[:card][:code], data[:card][:order_id], total_amount(data[:card][:amount], data[:card][:code]))
          @wallet.update!(available_balance: @wallet.available_balance - total_amount(data[:card][:amount], data[:card][:code]), cleared_balance: @wallet.cleared_balance - total_amount(data[:card][:amount], data[:card][:code]))
          create_order(transaction_log, data[:card][:order_id], data[:card][:amount], data[:card][:code], @data_hash['response'][0], total_amount(data[:card][:amount], data[:card][:code]))
        
          test_response

        else
          json_response({
            status: 402,
            data: nil,
            message: 'Error',
            errMessage: "Your test wallet is inactive. Please fund your wallet to activate, before proceeding."}, :payment_required)
        end
      end
    rescue Exception => e
      failure_notifier(data, transaction_log, e)
      raise ExceptionHandler::RegularError, e
    end
  end




  def vendor_send_card
    # begin
      # if in test mode, do something in test mode
      raise ExceptionHandler::RegularError, "data object is missing from request body" if params[:data].blank?
       data = params[:data]
       apikey=nil
       apikey = request.headers['x-auth-apikey'] unless  request.headers['x-auth-apikey'].blank?
       apikey = data[:apikey] unless data[:apikey].blank?
       handle_total_amount = total_amount(data[:card][:amount], data[:card][:code])
      if ENV['TEST_MODE'] == "true" || ENV['TEST_MODE'] == true
        test_response

       # APIKey validation
      elsif apikey.include?(vendor_secret_key_prefix[:live])
        # if current_business.is_live?
          ledger = Ledger.find_by!(profile_id: @current_user.profiles.first.id, is_test: false)
          # if  live and wallet is active
          # Wallet validation
          errors = ValidateNewTransaction.new(
            current_user: @current_user,
            amount: total_amount(data[:card][:amount], data[:card][:code]),
            transaction_type: 'send_vendor',
            wallet: nil,
            transaction_log: nil,
            ledger: ledger
          ).execute!
          if errors.count > 0
            json_response({
              status: 422,
              data: nil,
              message: "Error",
              errMessage: errors[0]
            }, :unprocessable_entity)
          elsif ledger.is_active? # check that the ledger is active
            if data[:card][:code].include?("sgc_")
              card_response = PerformVendorLocalTransaction.new(
                current_user: @current_user,
                transaction_type: "send",
                ledger: ledger,
                data: params[:data].to_unsafe_h,
                total_amount: total_amount(data[:card][:amount], data[:card][:code]),
                gift_card_name: @gift_card_name,
                gift_card_logo: @gift_card_logo,
                gift_card_min_range: @gift_card_min_range,
                gift_card_max_range: @gift_card_max_range,
                response_hash: @data_hash['response']
              ).execute!
            else
              card_response = PerformVendorTransaction.new(
                current_user: @current_user,
                transaction_type: "send",
                ledger: ledger,
                data: params[:data].to_unsafe_h,
                total_amount: total_amount(data[:card][:amount], data[:card][:code]),
                gift_card_name: @gift_card_name,
                gift_card_logo: @gift_card_logo,
                gift_card_min_range: @gift_card_min_range,
                gift_card_max_range: @gift_card_max_range,
              ).execute!
            end
            

            result = card_response.length ? card_response[0] : card_response

            json_response({
              status: 200,
              data: result,
              message: "success",
              errMessage: nil
              })
          else
            json_response({
              status: 402,
              data: nil,
              message: 'Error',
              errMessage: "your ledger account is inactive. please contact support for assistance"}, :payment_required)
          end
    
      else
        
        # APIKey validation
        ledger = Ledger.find_by!(profile_id: @current_user.profiles.first.id, is_test: true)
        # if test and ledger is active
        # Ledger validation
        errors = ValidateNewTransaction.new(
          current_user: @current_user,
          amount: total_amount(data[:card][:amount], data[:card][:code]),
          transaction_type: 'send_vendor',
          wallet: nil,
          transaction_log: nil,
          ledger: ledger
        ).execute!
        if errors.count > 0
          json_response({
            status: 422,
            data: nil,
            message: "Error",
            errMessage: errors[0]
          }, :unprocessable_entity)

        elsif ledger.is_active? # check that the wallet is active

          dest =  ENV['MAIL_FROM'] || data[:dest]

          if data[:card][:code] == "1334"
           dest = data[:dest]  
          end


          credit = ledger.credit.try(:to_d)
          debit = ledger.debit.try(:to_d)
          if ledger.credit.try(:to_d) > 0 && ledger.credit - handle_total_amount.try(:to_d) > 0
            credit = ledger.credit.try(:to_d) - handle_total_amount.try(:to_d) 
          else
            debit = ledger.debit.try(:to_d) + handle_total_amount.try(:to_d)
          end
          balance = credit - debit
          
          ledger.update!(balance: balance, credit: credit, debit: debit)

          ledger_history = create_ledger_history(ledger, :send_vendor, data[:card][:dest], data[:card][:amount], 'gift_card', handle_total_amount)
          
          transaction_log = create_transaction_log_vendor(ledger, ledger_history, :send, 'pending', data[:card][:code], data[:card][:order_id], handle_total_amount)

          payload ={
            "action": "#{data[:action]}",
            "apikey": "#{ENV['CARD_VENDOR_API_KEY'] || ENV['API_KEY']}",
            "sender": "#{data[:sender] || @current_user.profiles.first.vendor.business_name || 'Digiftng'}",
            "from": "#{ENV['ADMIN_PHONE_NUMBER']|| data[:from]}",
            "dest": "#{dest}",
            "code": "#{data[:card][:code]}",
            "amount": data[:card][:amount],
            "postal": "#{data[:postal] || ENV['DIGIFTNG_POSTAL'] }",
            "msg": "#{data[:msg]}",
            "reference": "#{transaction_log.reference_id}",
            "handle_delivery": true
        }
        

          create_order(transaction_log, data[:card][:order_id], data[:card][:amount], data[:card][:code], @data_hash['response'][0], handle_total_amount)
          transaction_log.update!(details: {data: data, payload: payload}, status: 'delivered', is_active: true)
          ledger_history.update!(status: true, details: @data_hash['response'][0])
          


          test_response

        else
          json_response({
            status: 402,
            data: nil,
            message: 'Error',
            errMessage: "your ledger account is inactive. please contact support for assistance"}, :payment_required)
        end
      end
    # rescue Exception => e
    #   failure_notifier(data, transaction_log, e)
    #   raise ExceptionHandler::RegularError, e
    # end
  end

  def send_retail_card
    begin
      if ENV['TEST_MODE'] == "true" || ENV['TEST_MODE'] == true
        data = params[:data]
        transaction_log = TransactionLog.find_by!(reference_id: data[:reference], status: 'test', is_active: true)
        create_order(transaction_log, data[:card][:order_id], data[:card][:amount], data[:card][:code], @data_hash['response'][0], total_amount(data[:card][:amount], data[:card][:code]))
        test_response
      else
        data = params[:data]
        transaction_log = TransactionLog.find_by!(reference_id: data[:reference], status: 'success', is_active: false)
        # else do something in live mode
        errors = ValidateNewRetailTransaction.new(
          current_user: @current_user,
          amount: total_amount(data[:card][:amount], data[:card][:code]),
          transaction_log: transaction_log,
        ).execute!
        if errors.count > 0
          json_response({
            status: 422,
            data: nil,
            message: "Error",
            errMessage: errors[0]
          }, :unprocessable_entity)
        else
          result = PerformRetailTransaction.new(
            current_user: @current_user,
            transaction_type: "send",
            transaction_log: transaction_log,
            data: params[:data].to_unsafe_h,
            total_amount: total_amount(data[:card][:amount], data[:card][:code]),
            gift_card_name: @gift_card_name
          ).execute!
          if result.length
            to = @current_user.email
              result.each do |card|
                if card['list'] && card['list'].length
                  card['list'].each do |item|
                    reference = item['reference']
                    logo = item['logo']
                    valid_address = data[:address] || ""
                    caption = item['caption']
                    if ENV['RAILS_ENV'] != 'production'
                      GiftCardMailer.voucher_purchase_notification(to, reference, logo, caption, valid_address).deliver_now
                    else
                      GiftCardMailer.voucher_purchase_notification(to, reference, logo, caption, valid_address).deliver_later
                    end
                  end
                end
              end
              # failure_notifier(data, transaction_log, e)  #only uncomment to test slack notification
            generate_cashtoken(@current_user.profiles.first.phone_number, transaction_log)
            json_response({
                status: 200,
                data: result,
                message: "success",
                errMessage: nil
            })
          else
            failure_notifier(data, transaction_log, :unprocessable_entity)
            json_response({
              status: 422,
              data: nil,
              message: "error",
              errMessage: nil
            }, :unprocessable_entity)
          end
        
        end
      end
    rescue Exception => e
      failure_notifier(data, transaction_log, e)
      raise(ExceptionHandler::RegularError, e)
    end
  end




  def send_retail_cards_for_cart
    begin
      if ENV['TEST_MODE'] == "true" || ENV['TEST_MODE'] == true
        data = params[:data]
        transaction_log = TransactionLog.find_by!(reference_id: data[:reference], status: 'test', is_active: true)
        create_order(transaction_log, data[:card][:order_id], data[:card][:amount], data[:card][:code], @data_hash['response'][0], total_amount(data[:card][:amount], data[:card][:code]))
        test_response
      else
        data = params[:data]
        raise ExceptionHandler::RegularError, "please supply cart_id" if data[:cart].blank?
          cards = []
          CartItem.find_each do |item|
            if (item.cart_id == data[:cart]) && item.is_active? && !item.is_deleted? && !item.checked_out?
              cards << {
                id: item.id,
                cart_id: item.cart_id,
                value: item.value, 
                quantity: item.quantity, 
                card_code: item.card_code
              }
            end
          end
          transaction_log = TransactionLog.find_by!(reference_id: data[:reference], status: 'success', is_active: false, cart_id: data[:cart])
      
          errors = ValidateNewRetailTransaction.new(
            current_user: @current_user,
            amount: total_amount_multiple(cards),
            transaction_log: transaction_log,
          ).execute!
          if errors.count > 0
            json_response({
              status: 422,
              data: nil,
              message: "Error",
              errMessage: errors[0]
            }, :unprocessable_entity)

          else
            result = PerformRetailTransaction.new(
              current_user: @current_user,
              transaction_type: "send",
              transaction_log: transaction_log,
              data: params[:data].to_unsafe_h.merge({cards: cards,  card: {}}),
              total_amount: total_amount_multiple(cards),
              gift_card_name: @gift_card_name
            ).execute!
    
            if result.length
              to = @current_user.email
                result.each do |card|
                  if card['list'] && card['list'].length
                    card['list'].each do |item|
                      reference = item['reference']
                      logo = item['logo']
                      valid_address = data[:address] || ""
                      caption = item['caption']
                      if ENV['RAILS_ENV'] != 'production'
                        GiftCardMailer.voucher_purchase_notification(to, reference, logo, caption, valid_address).deliver_now
                      else
                        GiftCardMailer.voucher_purchase_notification(to, reference, logo, caption, valid_address).deliver_later
                      end
                    end
                  end
                end
              json_response({
                  status: 200,
                  data: result,
                  message: "success",
                  errMessage: nil
              })
            else
              failure_notifier(data, transaction_log, :unprocessable_entity)
              json_response({
                status: 401,
                data: nil,
                message: "error",
                errMessage: nil
              }, :unprocessable_entity)
            end
            
          end 
      end
    rescue Exception => e
      failure_notifier(data, transaction_log, e)
      raise(ExceptionHandler::RegularError, e)
    end
  end

  def send_tmp_retail_card
    begin
      if ENV['TEST_MODE'] == "true" || ENV['TEST_MODE'] == true
        data = params[:data]
        transaction_log = TransactionLog.find_by!(reference_id: data[:reference], status: 'test', is_active: true)
        create_order(transaction_log, data[:card][:order_id], data[:card][:amount], data[:card][:code], @data_hash['response'][0], total_amount(data[:card][:amount], data[:card][:code]))
        test_response
      else
        data = params[:data]
        transaction_log = TransactionLog.find_by!(reference_id: data[:reference], status: 'success', is_active: false)
        profile_id = transaction_log.profile_id
        @current_user = Profile.find_by(id: profile_id).user
        # else do something in live mode
        errors = ValidateNewRetailTransaction.new(
          current_user: @current_user,
          amount: total_amount(data[:card][:amount], data[:card][:code]),
          transaction_log: transaction_log,
        ).execute!
        if errors.count > 0
          json_response({
            status: 422,
            data: nil,
            message: "Error",
            errMessage: errors[0]
          }, :unprocessable_entity)
        else
          result = PerformRetailTransaction.new(
            current_user: @current_user,
            transaction_type: "send",
            transaction_log: transaction_log,
            data: params[:data].to_unsafe_h,
            total_amount: total_amount(data[:card][:amount], data[:card][:code]),
            gift_card_name: @gift_card_name
          ).execute!




          if result.length
            to = @current_user.email
              result.each do |card|
                if card['list'] && card['list'].length
                  card['list'].each do |item|
                    reference = item['reference']
                    logo = item['logo']
                    valid_address = data[:address] || ""
                    caption = item['caption']
                    if ENV['RAILS_ENV'] != 'production'
                      GiftCardMailer.voucher_purchase_notification(to, reference, logo, caption, valid_address).deliver_now
                    else
                      GiftCardMailer.voucher_purchase_notification(to, reference, logo, caption, valid_address).deliver_later
                    end
                  end
                end
              end
            json_response({
                status: 200,
                data: result,
                message: "success",
                errMessage: nil
            })
          else
            failure_notifier(data, transaction_log, e)
            json_response({
              status: 401,
              data: result,
              message: "",
              errMessage: nil
            }, :unprocessable_entity)
          end
        end
      end
    rescue Exception => e
      failure_notifier(data, transaction_log, e)
      raise(ExceptionHandler::RegularError, e)
    end
  end


  protected
 

  private


  def create_transaction_log(wallet, wallet_history, transaction_type, status, gift_card_code, unique_card_order_id, total_amount)
    TransactionLog.create!(
        wallet: wallet,
        wallet_history: wallet_history,
        reference_id: unique_card_order_id || generate_ref_id,
        profile_id: @current_user.profiles.first.id,
        gift_card_code: gift_card_code,
        log_type: transaction_type,
        status: status,
        amount: total_amount,
        is_active: false,
        transaction_rate: Fx.get_rate
    )
end

def create_transaction_log_vendor(ledger, ledger_history, transaction_type, status, gift_card_code, unique_card_order_id, total_amount)
  TransactionLog.create!(
      ledger_id: ledger.id,
      ledger_history_id: ledger_history.id,
      reference_id: unique_card_order_id || generate_ref_id,
      profile_id: @current_user.profiles.first.id,
      gift_card_code: gift_card_code,
      log_type: transaction_type,
      status: status,
      amount: total_amount,
      is_active: false,
      transaction_rate: Fx.get_rate
  )
end

def create_wallet_history(wallet, transaction_type, dest, amount, category, total_amount)
    available_balance = wallet.available_balance
    profile = @current_user.profiles.first

    WalletHistory.create!(
        wallet: wallet,
        profile_id: profile.id,
        sender_details: profile,
        preference: '',
        details: {},
        category: category,
        amount: amount,
        balance: available_balance,
        commission: nil,
        actual_amount: total_amount,
        description: '',
        reference_code: '',
        status: true,
        is_active: true
    )
end

def create_order(transaction_log, unique_card_order_id, amount, gift_card_code, response, total_amount)
    profile =  @current_user.profiles.first
    Order.create!(
        profile: profile,
        transaction_log: transaction_log,
        card_order_id: unique_card_order_id || generate_ref_id,
        total_amount: total_amount,
        amount: amount,
        quantity: 1,
        gift_card_code: gift_card_code,
        details: response,
        order_type: 'send',
        status: 'success',
        is_active: true
    )
end

def create_ledger_history(ledger, transaction_type, dest, amount, category, total_amount)
  available_balance = ledger.balance
  profile = @current_user.profiles.first
  vendor = Vendor.find_by!(profile: profile)

  LedgerHistory.create!(
      vendor: vendor,
      ledger: ledger,
      profile_id: profile.id,
      sender_details: profile,
      preference: '',
      details: {},
      category: category,
      amount: amount,
      balance: available_balance,
      actual_amount: total_amount,
      description: '',
      reference_code: '',
      status: true,
      is_active: true
  )
end

 

  def test_response
    json_response({
      status: 200,
      data: @data_hash['response'][0],
      message: "this is a test result",
      errMessage: nil
      })
  end

  def rate
    Fx.get_rate
  end

  def fetch_available_gift_card
    threaded_response = {
      :blinksky_response=> [], 
      :custom_cards=>[], 
      :suregift_response=>[]
    }
    res = Concurrent::Promise.execute do
      begin
        blinksky_response = RestClient.post("#{ENV['CARD_VENDOR_API_V1'] || ENV['BLINKSKY_API_V1']}/catalog",
            {
              "service": {"apikey": "#{ENV['CARD_VENDOR_API_KEY'] || ENV['API_KEY']}"}
            }.to_json,
            {content_type: :json, accept: :json}
          )

          suregift_response = RestClient.get("#{ENV['SUREGIFTS_API_V1']}/GetJSONMerchants",
            {
              Authorization: "Basic " + Base64::encode64("#{ENV['SUREGIFTS_USERNAME']}:#{ENV['SUREGIFTS_PASSWORD']}"), content_type: :json, accept: :json
            }
          )
          [{
            :blinksky_response=> JSON(blinksky_response.body)['d'], 
            :suregift_response=> JSON(suregift_response).try(:[], "Data").try(:[], "data").try(:[], "Data")
          }]
      rescue => exception
        raise StandardError.new("failed to fetch available gift cards!")
      end
    end
    @fetch_available_gift_card_response = res.value!.first
  end

  def fetch_harmonized_available_gift_card
      begin
        @suregift_response = []
        @harmonized_response = []
        @custom_cards = []
        @blinksky_response = []

        threaded_response = {
          :blinksky_response=> [], 
          :custom_cards=>[], 
          :suregift_response=>[]
        }
        res = Concurrent::Promise.execute do
          begin
            custom_cards = []
            blinksky_response = RestClient.post("#{ENV['CARD_VENDOR_API_V1'] || ENV['BLINKSKY_API_V1']}/catalog",
                {
                  "service": {"apikey": "#{ENV['CARD_VENDOR_API_KEY'] || ENV['API_KEY']}"}
                }.to_json,
                {content_type: :json, accept: :json}
              )

              CustomGiftCard.find_each do |card|
                custom_cards << ActiveModelSerializers::SerializableResource.new(card, each_serializer: CustomGiftCardSerializer) if card.try(:is_active) && !card.try(:is_disabled)
              end
              custom_cards = custom_cards.sort!{ |a,b|  a.caption <=> b.caption }

              suregift_response = RestClient.get("#{ENV['SUREGIFTS_API_V1']}/GetJSONMerchants",
                {
                  Authorization: "Basic " + Base64::encode64("#{ENV['SUREGIFTS_USERNAME']}:#{ENV['SUREGIFTS_PASSWORD']}"), content_type: :json, accept: :json
                }
              )
              [{
                :blinksky_response=> JSON(blinksky_response.body)['d'], 
                :custom_cards=> custom_cards, 
                :suregift_response=> JSON(suregift_response).try(:[], "Data").try(:[], "data").try(:[], "Data")
              }]
          rescue => exception
            raise StandardError.new("failed to fetch available gift cards!")
          end
        end
      
        threaded_response = res.value[0] unless res.rejected?


        @blinksky_response = threaded_response.try(:[], :blinksky_response) if threaded_response.try(:[], :blinksky_response) 

        @custom_cards = threaded_response.try(:[], :custom_cards) if threaded_response.try(:[], :custom_cards)
        @suregift_response = threaded_response.try(:[], :suregift_response)  if threaded_response.try(:[], :suregift_response)

        @harmonized_response = @harmonized_response.concat sanitize_with_keys_response(@blinksky_response, ENV["CARD_TYPE_FOREIGN"] || "foreign")
        @harmonized_response.concat sanitize_response(@suregift_response)
        @harmonized_response = @harmonized_response.concat(sanitize_with_keys_response(@custom_cards, ENV["CARD_TYPE_CUSTOM"] || "custom"))
        @harmonized_response = @harmonized_response.sort!{ |a,b|  JSON.parse(a.to_json)["caption"] <=> JSON.parse(b.to_json)["caption"] }

        @harmonized_response

      rescue => e
        json_response({
          status: 404,
          data: [],
          message: "Error",
          errMessage: e.message || "Oops, can't fetch giftcards at this time"
          }, :not_found)
      end
  end

  def failure_notifier(payload=nil, transaction=nil, err=nil)
    if payload.blank? || transaction.blank? || err.blank?
      return
    end
    if ENV['RAILS_ENV'] != 'production'
      SendUserDropoffNotificationJob.perform_now(@current_user, transaction, err, payload)
    else
      SendUserDropoffNotificationJob.perform_later(@current_user, transaction, err, payload)
    end
  end
  
end