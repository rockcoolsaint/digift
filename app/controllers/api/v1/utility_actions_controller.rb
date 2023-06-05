class Api::V1::UtilityActionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_proxy_url

  
  def get_service_types
    data = [{
      "title": "DStv",
      "value": "dstv",
      "is_active": true
    },
    {
      "title": "GOtv",
      "value": "gotv",
      "is_active": true
    },
    {
      "title": "StarTimes",
      "value": "startimes",
      "is_active": true
    }]
  
    json_response({
      status: 200,
      data: data,
      message: "success",
      errMessage: nil
    })

  rescue Exception => e
    raise(ExceptionHandler::RegularError, e)
  end
  


 

  def utility_providers_bouquets
    begin
      res = Concurrent::Future.execute do
        # some parallel work
        @payload = {
          "service_type" => "#{params[:service_type]}"
        }

        @response = RestClient.post("#{ENV['UTILITY_VENDOR_SERVICE_API_V1']}/services/multichoice/list",
          @payload.to_json,
          {:Authorization => "Api-key #{ENV['UTILITY_VENDOR_API_KEY']}", content_type: :json, accept: :json}
        )
        data = JSON(@response)
        json_response({
          status: 200,
          data: data['data'],
          message: "success",
          errMessage: nil
        })
      end
      res.value!
    rescue RestClient::Exceptions::OpenTimeout => e
      raise(ExceptionHandler::RestClientExceptionsOpenTimeout, e)

    rescue RestClient::ExceptionWithResponse => e
      data = JSON(e.response)
      json_response({
        status: e.http_code,
        data: data,
        message: nil,
        errMessage: data.try(:[], "message") || e.default_message || e.message || 'Oops, something went wrong'
      }, e.http_code)

    rescue Exception => e
      raise(ExceptionHandler::RegularError, e)
    ensure
      unset_proxy_url
    end
  end


  def utility_providers_bouquets_addons
    begin
      res = Concurrent::Future.execute do
        # some parallel work
        @payload = {
          "service_type" => "#{params[:service_type]}",
          "product_code" => "#{params[:product_code]}"
        }

        @response = RestClient.post("#{ENV['UTILITY_VENDOR_SERVICE_API_V1']}/services/multichoice/addons",
          @payload.to_json,
          {:Authorization => "Api-key #{ENV['UTILITY_VENDOR_API_KEY']}", content_type: :json, accept: :json}
        )
        data = JSON(@response)
        json_response({
          status: 200,
          data: data['data'],
          message: "success",
          errMessage: nil
        })
      end
      res.value!
    rescue RestClient::Exceptions::OpenTimeout => e
      raise(ExceptionHandler::RestClientExceptionsOpenTimeout, e)

    rescue RestClient::ExceptionWithResponse => e
      data = JSON(e.response)
      json_response({
        status: e.http_code,
        data: data,
        message: nil,
        errMessage: data.try(:[], "message") || e.default_message || e.message || 'Oops, something went wrong'
      }, e.http_code)

    rescue Exception => e
      raise(ExceptionHandler::RegularError, e)
    ensure
      unset_proxy_url
    end
  end




  def utility_account_verify
    begin
      res = Concurrent::Future.execute do
        # some parallel work
        @payload = {
          "service_type" => "#{params[:service_type]}",
          "account_number" => "#{params[:account_number]}"
        }

        @response = RestClient.post("#{ENV['UTILITY_VENDOR_SERVICE_API_V1']}/services/namefinder/query",
          @payload.to_json,
          {:Authorization => "Api-key #{ENV['UTILITY_VENDOR_API_KEY']}", content_type: :json, accept: :json}
        )
        data = JSON(@response)
        json_response({
          status: 200,
          data: data['data'],
          message: "success",
          errMessage: nil
        })
      end
      res.value!
    rescue RestClient::Exceptions::OpenTimeout => e
      failure_notifier(@payload, e)
      raise(ExceptionHandler::RestClientExceptionsOpenTimeout, e)

    rescue RestClient::ExceptionWithResponse => e
      data = JSON(e.response)
      failure_notifier(@payload, e)
      json_response({
        status: e.http_code,
        data: data,
        message: nil,
        errMessage: data.try(:[], "message") || e.default_message || e.message || 'Oops, something went wrong'
      }, e.http_code)

    rescue Exception => e
      failure_notifier(@payload, e)
      raise(ExceptionHandler::RegularError, e)
    ensure
      unset_proxy_url
    end
  end

  def utility_renewal
    data = params[:data]
    service_type = data[:service_type]
    begin
      if ENV['TEST_MODE'] == "true" || ENV['TEST_MODE'] == true
        data = params[:data]
        # test_response(data["destination"], data["amount"])
      else
        data = params[:data]
        raise(ExceptionHandler::RegularError, 'data field is requies') if data.blank?

        @transaction_log = TransactionLog.find_by!(reference_id: data[:reference], status: 'success', is_active: false)
        errors = ValidateNewTransaction.new(
          current_user: @current_user,
          amount: data[:total_amount],
          transaction_type: 'cabletv',
          wallet: nil,
          transaction_log: @transaction_log,
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
            promo = Promo.where(is_active: true)
            if promo.exists? || (ENV["DISCOUNT_PERIOD"] == 'true' || ENV["DISCOUNT_PERIOD"] == true)
              promo = Promo.find_by(is_active: true)
              if promo.try(:current_count) && (promo.current_count >= promo.final_count)
                promo.update!(current_count: 1)
                if PromoWinner.where(transaction_log_id: @transaction_log.id).exists?
                  PromoWinner.find_by(transaction_log_id: @transaction_log.id).update!(is_completed: true)
                end
              else
                promo = Promo.where(is_active: true)
                if promo.exists?
                  promo = Promo.find_by(is_active: true)
                  promo.update!(current_count: (promo.current_count + 1))
                end
              end
            end

            service_type = data[:service_type]
            @payload = {
              "total_amount" => "#{data[:total_amount]}",
              "product_monthsPaidFor" => "#{data[:product_monthsPaidFor]}",
              "product_code" => "0",
              "service_type" => "#{service_type}",
              "agentId" => "#{ENV['UTILITY_VENDOR_SERVICE_AGENT_ID'] || "1"}",
              "agentReference" => "#{data[:reference]}",
              "smartcard_number" => "#{data[:smartcard_number]}"
            }
            @payload[:isBoxOffice] = "#{data[:isBoxOffice]}" if !data[:isBoxOffice].blank?

            @response = RestClient.post("#{ENV['UTILITY_VENDOR_SERVICE_API_V1']}/services/multichoice/request",
              @payload.to_json,
              {:Authorization => "Api-key #{ENV['UTILITY_VENDOR_API_KEY']}", content_type: :json, accept: :json}
            )

            data = JSON(@response)
            @transaction_log.update!(details: @transaction_log.details.merge({data: data, payload: @payload}), status: 'delivered', is_active: true, gift_card_name: service_type)
            # cashtoken reward
            generate_cashtoken(@current_user.profiles.first.phone_number, @transaction_log)

            to = @current_user.email

            if ENV['RAILS_ENV'] != 'production'
              UtilityMailer.utility_renewal_cabletv_notification(to, service_type).deliver_now
            else
              UtilityMailer.utility_renewal_cabletv_notification(to, service_type).deliver_later
            end

            json_response({
              status: 200,
              data: data['data'],
              message: "success",
              errMessage: nil
            })
          end
          res.value!
        end
      end

    rescue RestClient::Exceptions::OpenTimeout => e
      failure_notifier(@payload, e, @transaction_log)
      data = JSON(e.response)
      transaction_fail(data, service_type)
      raise(ExceptionHandler::RestClientExceptionsOpenTimeout, e)

    rescue RestClient::ExceptionWithResponse => e
      failure_notifier(@payload, e)
      data = JSON(e.response)
      transaction_fail(data, service_type)
      json_response({
        status: e.http_code,
        data: data,
        message: nil,
        errMessage: data.try(:[], "message") || e.default_message || e.message || 'Oops, something went wrong'
      }, e.http_code)

    rescue Exception => e
      failure_notifier(@payload, e, @transaction_log)
      data = JSON(e.response)
      transaction_fail(data, service_type)
      raise(ExceptionHandler::RegularError, e)
    ensure
      unset_proxy_url
    end
  end

  def utility_change_subscription
    data = params[:data]
    service_type = data[:service_type]
    begin
      if ENV['TEST_MODE'] == "true" || ENV['TEST_MODE'] == true
        data = params[:data]
        # test_response(data["destination"], data["amount"])
      else
        data = params[:data]
        raise(ExceptionHandler::RegularError, 'data field is requies') if data.blank?

        @transaction_log = TransactionLog.find_by!(reference_id: data[:reference], status: 'success', is_active: false)
        errors = ValidateNewTransaction.new(
          current_user: @current_user,
          amount: data[:total_amount],
          transaction_type: 'cabletv',
          wallet: nil,
          transaction_log: @transaction_log,
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

            promo = Promo.where(is_active: true)
            if promo.exists? || (ENV["DISCOUNT_PERIOD"] == 'true' || ENV["DISCOUNT_PERIOD"] == true)
              promo = Promo.find_by(is_active: true)
              if promo.try(:current_count) && (promo.current_count >= promo.final_count)
                promo.update!(current_count: 1)
                if PromoWinner.where(transaction_log_id: @transaction_log.id).exists?
                  PromoWinner.find_by(transaction_log_id: @transaction_log.id).update!(is_completed: true)
                end
              else
                promo = Promo.where(is_active: true)
                if promo.exists?
                  promo = Promo.find_by(is_active: true)
                  promo.update!(current_count: (promo.current_count + 1))
                end
              end
            end


            service_type = data[:service_type]
            @payload = {
              "total_amount" => "#{data[:total_amount]}",
              "product_monthsPaidFor" => "#{data[:product_monthsPaidFor]}",
              "addon_monthsPaidFor" => "#{data[:addon_monthsPaidFor]}",
              "product_code" => "#{data[:product_code]}",
              "service_type" => "#{data[:service_type]}",
              "agentId" => "#{ENV['UTILITY_VENDOR_SERVICE_AGENT_ID'] || '1'}",
              "agentReference" => "#{data[:reference]}",
              "smartcard_number" => "#{data[:smartcard_number]}"
            }

            @payload[:addon_code] = "#{data[:addon_code]}" if !data[:addon_code].blank?

            @payload[:addon_monthsPaidFor] = "#{data[:addon_monthsPaidFor]}" if !data[:addon_monthsPaidFor].blank? && !data[:addon_code].blank?

            @response = RestClient.post("#{ENV['UTILITY_VENDOR_SERVICE_API_V1']}/services/multichoice/request",
              @payload.to_json,
              {:Authorization => "Api-key #{ENV['UTILITY_VENDOR_API_KEY']}", "Baxi-date": Date.today.to_s, content_type: :json, accept: :json}
            )

            data = JSON(@response)
            @transaction_log.update!(details: @transaction_log.details.merge({data: data, payload: @payload}), status: 'delivered', is_active: true, gift_card_name: service_type)

            generate_cashtoken(@current_user.profiles.first.phone_number, @transaction_log)

            to = @current_user.email

            if ENV['RAILS_ENV'] != 'production'
              UtilityMailer.utility_change_cabletv_notification(to, service_type).deliver_now
            else
              UtilityMailer.utility_change_cabletv_notification(to, service_type).deliver_later
            end

            json_response({
              status: 200,
              data: data['data'],
              message: "success",
              errMessage: nil
            })
          end
          res.value!
        end
      end

    rescue RestClient::Exceptions::OpenTimeout => e
      failure_notifier(@payload, e, @transaction_log)
      data = JSON(e.response)
      transaction_fail(data, service_type)
      raise(ExceptionHandler::RestClientExceptionsOpenTimeout, e)

    rescue RestClient::ExceptionWithResponse => e
      failure_notifier(@payload, e, @transaction_log)
      data = JSON(e.response)
      transaction_fail(data, service_type)
      json_response({
        status: e.http_code,
        data: data,
        message: nil,
        errMessage: data.try(:[], "message") || e.default_message || e.message || 'Oops, something went wrong'
      }, e.http_code)

    rescue Exception => e
      failure_notifier(@payload, e, @transaction_log)
      raise(ExceptionHandler::RegularError, e)
    ensure
      unset_proxy_url
    end
  end



  def utility_electricity_providers
    begin
      res = Concurrent::Future.execute do
        # some parallel work
        @response = RestClient.get("#{ENV['UTILITY_VENDOR_SERVICE_API_V1']}/services/electricity/billers",
          {:Authorization => "Api-key #{ENV['UTILITY_VENDOR_API_KEY']}", content_type: :json, accept: :json}
        )
        data = JSON(@response)
        json_response({
          status: 200,
          data: data['data'],
          message: "success",
          errMessage: nil
        })
      end
      res.value!
    rescue RestClient::Exceptions::OpenTimeout => e
      raise(ExceptionHandler::RestClientExceptionsOpenTimeout, e)

    rescue RestClient::ExceptionWithResponse => e
      data = JSON(e.response)
      json_response({
        status: e.http_code,
        data: data,
        message: nil,
        errMessage: data.try(:[], "message") || e.default_message || e.message || 'Oops, something went wrong'
      }, e.http_code)

    rescue Exception => e
      data = JSON(e.response)
      transaction_fail(data, service_type)
      raise(ExceptionHandler::RegularError, e)
    ensure
      unset_proxy_url
    end
  end

  def utility_pay_electric
    data = params[:data]
    service_type = data[:service_type]
    begin
      if ENV['TEST_MODE'] == "true" || ENV['TEST_MODE'] == true
        data = params[:data]
        # test_response(data["destination"], data["amount"])
      else
        raise(ExceptionHandler::RegularError, 'data field is requies') if data.blank?

        @transaction_log = TransactionLog.find_by!(reference_id: data[:reference], status: 'success', is_active: false)
        errors = ValidateNewTransaction.new(
          current_user: @current_user,
          amount: data[:amount],
          transaction_type: 'electricbill',
          wallet: nil,
          transaction_log: @transaction_log,
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

            promo = Promo.where(is_active: true)
            if promo.exists? || (ENV["DISCOUNT_PERIOD"] == 'true' || ENV["DISCOUNT_PERIOD"] == true)
              promo = Promo.find_by(is_active: true)
              if promo.try(:current_count) && (promo.current_count >= promo.final_count)
                promo.update!(current_count: 1)
                if PromoWinner.where(transaction_log_id: @transaction_log.id).exists?
                  PromoWinner.find_by(transaction_log_id: @transaction_log.id).update!(is_completed: true)
                end
              else
                promo = Promo.where(is_active: true)
                if promo.exists?
                  promo = Promo.find_by(is_active: true)
                  promo.update!(current_count: (promo.current_count + 1))
                end
              end
            end


            @payload = {
              "phone" => "#{data[:phone]}",
              "amount" => data[:amount],
              "account_number" => "#{data[:account_number]}",
              "service_type" => "#{service_type}",
              "agentId" => "#{ENV['UTILITY_VENDOR_SERVICE_AGENT_ID'] || "1"}",
              "agentReference" => "#{data[:reference]}"
            }

            @response = RestClient.post("#{ENV['UTILITY_VENDOR_SERVICE_API_V1']}/services/electricity/request",
              @payload.to_json,
              {:Authorization => "Api-key #{ENV['UTILITY_VENDOR_API_KEY']}", "Baxi-date": Date.today.to_s, content_type: :json, accept: :json}
            )

            data = JSON(@response)
            @transaction_log.update!(details: @transaction_log.details.merge({data: data, payload: @payload}), status: 'delivered', is_active: true, gift_card_name: service_type)

            generate_cashtoken(@current_user.profiles.first.phone_number, @transaction_log)

            to = @current_user.email

            if ENV['RAILS_ENV'] != 'production'
              UtilityMailer.utility_pay_electric_notification(to, service_type, data).deliver_now
            else
              UtilityMailer.utility_pay_electric_notification(to, service_type, data).deliver_later
            end

            json_response({
              status: 200,
              data: data['data'],
              message: "success",
              errMessage: nil
            })
          end
          res.value!
        end
      end

    rescue RestClient::Exceptions::OpenTimeout => e
      data = JSON(e) 
      data = JSON(e.response)  if e.try(:response)
      failure_notifier(@payload, e, @transaction_log)
      transaction_fail(data, service_type)
      raise(ExceptionHandler::RestClientExceptionsOpenTimeout, e)

    rescue RestClient::ExceptionWithResponse => e
      data = JSON(e.response)
      failure_notifier(@payload, e, @transaction_log)
      transaction_fail(data, service_type)
      json_response({
        status: e.http_code,
        data: data,
        message: nil,
        errMessage: data.try(:[], "message") || e.default_message || e.message || 'Oops, something went wrong'
      }, e.http_code)
    rescue ActiveRecord::RecordNotFound => e
      failure_notifier(@payload, e, @transaction_log)
      transaction_fail(data, service_type)
      raise(ExceptionHandler::RegularError, e)

    rescue Exception => e
      failure_notifier(@payload, e, @transaction_log)
      transaction_fail(e, service_type)
      raise(ExceptionHandler::RegularError, e)
    ensure
      unset_proxy_url
    end
  end

  def epin_service_providers
    begin
      res = Concurrent::Future.execute do
        # some parallel work
        @response = RestClient.get("#{ENV['UTILITY_VENDOR_SERVICE_API_V1']}/services/epin/providers",
          {:Authorization => "Api-key #{ENV['UTILITY_VENDOR_API_KEY']}", content_type: :json, accept: :json}
        )
        data = JSON(@response)
        json_response({
          status: 200,
          data: data['data'],
          message: "success",
          errMessage: nil
        })
      end
      res.value!
    rescue RestClient::Exceptions::OpenTimeout => e
      raise(ExceptionHandler::RestClientExceptionsOpenTimeout, e)

    rescue RestClient::ExceptionWithResponse => e
      data = JSON(e.response)
      json_response({
        status: e.http_code,
        data: data,
        message: nil,
        errMessage: data.try(:[], "message") || e.default_message || e.message || 'Oops, something went wrong'
      }, e.http_code)

    rescue Exception => e
      raise(ExceptionHandler::RegularError, e)
    ensure
      unset_proxy_url
    end
  end

  def epin_bundle_retrieval
    begin
      res = Concurrent::Future.execute do
        # some parallel work
        @payload = {
          "service_type" => "#{params[:service_type]}"
        }

        @response = RestClient.post("#{ENV['UTILITY_VENDOR_SERVICE_API_V1']}/services/epin/bundles",
          @payload.to_json,
          {:Authorization => "Api-key #{ENV['UTILITY_VENDOR_API_KEY']}", content_type: :json, accept: :json}
        )
        data = JSON(@response)
        json_response({
          status: 200,
          data: data['data'],
          message: "success",
          errMessage: nil
        })
      end
      res.value!
    rescue RestClient::Exceptions::OpenTimeout => e
      failure_notifier(@payload, e)
      raise(ExceptionHandler::RestClientExceptionsOpenTimeout, e)

    rescue RestClient::ExceptionWithResponse => e
      data = JSON(e.response)
      failure_notifier(@payload, e)
      json_response({
        status: e.http_code,
        data: data,
        message: nil,
        errMessage: data.try(:[], "message") || e.default_message || e.message || 'Oops, something went wrong'
      }, e.http_code)

    rescue Exception => e
      failure_notifier(@payload, e)
      raise(ExceptionHandler::RegularError, e)
    ensure
      unset_proxy_url
    end
  end

  def epin_purchase
    data = params[:data]
    service_type = data[:service_type]
    begin
      if ENV['TEST_MODE'] == "true" || ENV['TEST_MODE'] == true
        data = params[:data]
        # test_response(data["destination"], data["amount"])
      else
        data = params[:data]
        raise(ExceptionHandler::RegularError, 'data field is required') if data.blank?

        amount = (data[:pin_value].try(:to_i) * data[:number_of_pins].try(:to_i))
        @transaction_log = TransactionLog.find_by!(reference_id: data[:reference], status: 'success', is_active: false)
        errors = ValidateNewTransaction.new(
          current_user: @current_user,
          amount: amount,
          transaction_type: 'epin',
          wallet: nil,
          transaction_log: @transaction_log,
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

            promo = Promo.where(is_active: true)
            if promo.exists? || (ENV["DISCOUNT_PERIOD"] == 'true' || ENV["DISCOUNT_PERIOD"] == true)
              promo = Promo.find_by(is_active: true)
              if promo.try(:current_count) && (promo.current_count >= promo.final_count)
                promo.update!(current_count: 1)
                if PromoWinner.where(transaction_log_id: @transaction_log.id).exists?
                  PromoWinner.find_by(transaction_log_id: @transaction_log.id).update!(is_completed: true)
                end
              else
                promo = Promo.where(is_active: true)
                if promo.exists?
                  promo = Promo.find_by(is_active: true)
                  promo.update!(current_count: (promo.current_count + 1))
                end
              end
            end


            service_type = data[:service_type]

            @payload = {
              "amount" => amount,
              "pinValue" => data[:pin_value].try(:to_i),
              "numberOfPins" => data[:number_of_pins].try(:to_i),
              "service_type" => "#{service_type}",
              "agentId" => "#{ENV['UTILITY_VENDOR_SERVICE_AGENT_ID'] || "1"}",
              "agentReference" => "#{data[:reference]}"
            }

            @response = RestClient.post("#{ENV['UTILITY_VENDOR_SERVICE_API_V1']}/services/epin/request",
              @payload.to_json,
              {:Authorization => "Api-key #{ENV['UTILITY_VENDOR_API_KEY']}", "Baxi-date": Date.today.to_s, content_type: :json, accept: :json}
            )

            data = JSON(@response)
            @transaction_log.update!(details: @transaction_log.details.merge({data: data, payload: @payload}), status: 'delivered', is_active: true, gift_card_name: service_type)

            generate_cashtoken(@current_user.profiles.first.phone_number, @transaction_log)

            to = @current_user.email

            if ENV['RAILS_ENV'] != 'production'
              UtilityMailer.utility_epin_purchase_notification(to, service_type, data).deliver_now
            else
              UtilityMailer.utility_epin_purchase_notification(to, service_type, data).deliver_later
            end

            json_response({
              status: 200,
              data: data['data'],
              message: "success",
              errMessage: nil
            })
          end
          res.value!
        end
      end

    rescue RestClient::Exceptions::OpenTimeout => e
      data = JSON(e.response)
      transaction_fail(data, service_type)
      failure_notifier(@payload, e, @transaction_log)
      raise(ExceptionHandler::RestClientExceptionsOpenTimeout, e)

    rescue RestClient::ExceptionWithResponse => e
      data = JSON(e.response)
      transaction_fail(data, service_type)
      failure_notifier(@payload, e, @transaction_log)
      json_response({
        status: e.http_code,
        data: data,
        message: nil,
        errMessage: data.try(:[], "message") || e.default_message || e.message || 'Oops, something went wrong'
      }, e.http_code)

    rescue Exception => e
      data = e
      data = JSON(e.response) if e.try(:response)
      failure_notifier(@payload, e, @transaction_log)
      transaction_fail(data, service_type)
      raise(ExceptionHandler::RegularError, e)
    ensure
      unset_proxy_url
    end
  end

  private
    def set_proxy_url
      RestClient.proxy = ENV["FIXIE_URL"] unless ENV["FIXIE_URL"].blank?
    end
    def unset_proxy_url
      RestClient.proxy = nil
    end

    def failure_notifier(payload, err=nil, transaction=nil)
      if ENV['RAILS_ENV'] != 'production'
        UtitilityVerifyFailureNotificationJob.perform_now(@current_user, payload.to_json, err, transaction)
      else
        UtitilityVerifyFailureNotificationJob.perform_later(@current_user, payload.to_json, err, transaction)
      end
    end

    # def transaction_fail(data, service_type)
    #   if @transaction_log.try(:exists?) && @transaction_log.exists?
    #     @transaction_log.update!(details: @transaction_log.details.merge({data: data, payload: @payload}), gift_card_name: service_type)
    #     @transaction_log.failed!
    #   end
    # end
end