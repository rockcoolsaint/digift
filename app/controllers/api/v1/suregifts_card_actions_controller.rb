class Api::V1::SuregiftsCardActionsController < ApplicationController
  before_action :fetch_available_gift_card, only: [:fetch, :send_retail_card]
  before_action :current_user_by_api_key, only: [:index]

  def index
    begin
      @response||= RestClient.get("#{ENV['SUREGIFTS_API_V1']}/GetJSONMerchants",
        {
          Authorization: "Basic " + Base64::encode64("#{ENV['SUREGIFTS_USERNAME']}:#{ENV['SUREGIFTS_PASSWORD']}"), content_type: :json, accept: :json
        }
      )
      json_response({
        status: 200,
        data: sanitize_response(JSON(@response).try(:[], "Data").try(:[], "data").try(:[], "Data")),
        message: "available local cards",
        errMessage: nil
        })
    rescue => e
      json_response({
        status: 500,
        data: nil,
        message: "Error",
        errMessage: e.message || "Oops, can't fetch giftcards at this time"
        }, :internal_server_error)
    rescue => e
        raise ExceptionHandler::RegularError, e
    end

  end

  def fetch
    index
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
         

          result = PerformLocalRetailTransaction.new(
            current_user: @current_user,
            transaction_type: "send",
            transaction_log: transaction_log,
            data: params[:data].to_unsafe_h,
            total_amount: total_amount(data[:card][:amount], data[:card][:code])
          ).execute!


          merchantId = params[:data][:card][:code][4..].to_i
          merchant = RestClient.get("#{ENV['SUREGIFTS_API_V1']}/GetJSONMerchantByID?merchantId=#{merchantId}",
            {
              Authorization: "Basic " + Base64::encode64("#{ENV['SUREGIFTS_USERNAME']}:#{ENV['SUREGIFTS_PASSWORD']}"), content_type: :json, accept: :json
            }
          )

          voucher_image = JSON(merchant).try(:[], "Data").try(:[], "Picture")
          item_name = JSON(merchant).try(:[], "Data").try(:[], "Name")

          if result.length
            to = @current_user.email
              result.each do |card|
                card["Data"].each do |item|
                  if item
                    valid_address = data[:address] || ""
                    voucher = item["Voucher"]
                    expiration = item["VoucherExpiryDate"]
                    if ENV['RAILS_ENV'] != 'production'
                      GiftCardMailer.voucher_local_purchase_notification(to, valid_address, voucher, data[:card][:amount], voucher_image, item_name, expiration).deliver_now
                    else
                      GiftCardMailer.voucher_local_purchase_notification(to, valid_address, voucher, data[:card][:amount], voucher_image, item_name, expiration).deliver_later
                    end
                  end
                end
              end

            generate_cashtoken(@current_user.profiles.first.phone_number, transaction_log)
            json_response({
                status: 200,
                data: result,
                message: "success",
                errMessage: nil
            })
          else
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
      raise(ExceptionHandler::RegularError, e)
    end
  end

  private

  # def total_amount(amount, code='')
  #     # get total amount of the individual card from data parameter multiplied by the fx_rate
  # raise(ExceptionHandler::DataType) if !amount.is_a?(Numeric)
  #   card_fee = 0.00
  #   # JSON(@response.body)['d'].each do |card|
  #   #   if card["code"] == code
  #   #     card_fee = card["fee"]
  #   #   end
  #   # end
  #   if code.include?("_")
  #     JSON(@response.body)["Data"]["data"]["Data"].each do |card|
  #       if code[4..] === (card["StoreId"]).to_s
  #         card_fee = card["fee"]
  #       end
  #     end
  #     total = (amount.to_d + card_fee.to_d)
  #   else
  #     JSON(@response.body)['d'].each do |card|
  #       if card["code"] == code
  #         card_fee = card["fee"]
  #       end
  #     end
  #     total = ((amount.to_d + card_fee.to_d) * rate.to_d)
  #   end
  # end

  def fetch_available_gift_card
    if @response.blank?
      @response = nil
      begin
        @response = RestClient.get("#{ENV['SUREGIFTS_API_V1']}/GetJSONMerchants",
          {
            Authorization: "Basic " + Base64::encode64("#{ENV['SUREGIFTS_USERNAME']}:#{ENV['SUREGIFTS_PASSWORD']}"), content_type: :json, accept: :json
          }
        )
      rescue => e
        json_response({
          status: 500,
          data: nil,
          message: "Error",
          errMessage: e.message || "Oops, can't fetch giftcards at this time"
          }, :internal_server_error)
      end
    end
  end
end
