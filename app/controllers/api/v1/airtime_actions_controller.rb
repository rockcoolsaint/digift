class Api::V1::AirtimeActionsController < ApplicationController
  before_action :authenticate_user!

  def purchase_airtime
    begin
      if ENV['TEST_MODE'] == "true" || ENV['TEST_MODE'] == true
        data = params[:data]
        raise(ExceptionHandler::RegularError, 'data field is requies') if data.blank?
        test_response(data["destination"], data["amount"])
      else
        data = params[:data]
        raise(ExceptionHandler::RegularError, 'data field is requies') if data.blank?

        transaction_log = TransactionLog.find_by!(reference_id: data[:reference], status: 'success', is_active: false)
        errors = ValidateNewTransaction.new(
          current_user: @current_user,
          amount: data[:amount],
          transaction_type: 'airtime',
          wallet: nil,
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
          res = Concurrent::Future.execute do
            # some parallel work
              amount = data[:amount]


              promo = Promo.where(is_active: true)
              if promo.exists? || (ENV["DISCOUNT_PERIOD"] == 'true' || ENV["DISCOUNT_PERIOD"] == true)
                promo = Promo.find_by(is_active: true)
                if promo.try(:current_count) && (promo.current_count >= promo.final_count)
                  promo.update!(current_count: 1)
                  if PromoWinner.where(transaction_log_id: transaction_log.id).exists?
                    PromoWinner.find_by(transaction_log_id: transaction_log.id).update!(is_completed: true)
                  end
                else
                  promo = Promo.where(is_active: true)
                  if promo.exists?
                    promo = Promo.find_by(is_active: true)
                    promo.update!(current_count: (promo.current_count + 1))
                  end
                end
              end

              payload = {
                "amount" => "#{amount}",
                "destination" => data[:destination],
              }
              @response = RestClient.post("#{ENV['DOJAH_VENDOR_API_URL_V1']}/purchase/airtime",
                payload.to_json,
                {:AppId => "#{ENV['DOJAH_VENDOR_APP_ID']}", :Authorization => "#{ENV['DOJAH_VENDOR_API_KEY']}", content_type: :json, accept: :json}
              )

            data = JSON(@response)
            transaction_log.update!(details: transaction_log.details.merge({data: data, payload: payload}), status: 'delivered', is_active: true, gift_card_name: "airtime")

            generate_cashtoken(@current_user.profiles.first.phone_number, transaction_log)

            json_response({
              status: 200,
              data: data,
              message: "success",
              errMessage: nil
            })
          end
          res.value!
        end
      end

    rescue RestClient::Exceptions::OpenTimeout => e
      raise(ExceptionHandler::RestClientExceptionsOpenTimeout, e)

    rescue RestClient::ExceptionWithResponse => e
      data = JSON(e.response)
      json_response({
        status: e.http_code,
        data: data,
        message: nil,
        errMessage: e.default_message || e.message || 'Oops, something went wrong'
      }, e.http_code)

    rescue Exception => e
      raise(ExceptionHandler::RegularError, e)
    end
  end

  protected

  def test_response(mobile="+2348109152844", amount="200")
    json_response({
      status: 200,
      data: {
          "entity": {
          "status": "Sent",
          "mobile": mobile,
          "amount": "NGN #{amount}.0000"
        }
      },
      message: "this is a test result",
      errMessage: nil
    })
  end

end
