class Api::V1::TransactionActionsController < ApplicationController
    # skip_before_action :
    before_action :authenticate_user!, except: [:create_make_tmp_transaction]
    before_action :validate_personal_user!, only: [:create_make_transaction]
    before_action :validate_business_user!, only: [:create_fund_wallet, :verify_fund_wallet]
    before_action :set_current_business, only: [:create_fund_wallet, :verify_fund_wallet]
    skip_before_action :authorize_request, only: [:verify_make_transaction]

    # create a wallet history with the amount from the transaction

    def create_fund_wallet
      begin
        if @current_user.profiles.first.test_mode?
          profile_id = @current_user.profiles.first.id
          wallet = Wallet.find_by!(business_id: @current_business.id, is_test: true)
          wallet_history_id = create_wallet_history(wallet).id
          reference = JsonWebToken.encode({ business_id: @current_business.id, profile_id: profile_id, wallet_history_id: wallet_history_id, amount: create_fundwallet_params[:amount].to_d })
          WalletHistory.find_by(id: wallet_history_id ).update!(reference_code: reference)
          json_response({
            status: 200,
            data: {
              reference: reference
            },
            message: 'this is your transaction reference, please keep it safe',
            errMessage: nil
          })
        else
          profile_id = @current_user.profiles.first.id
          wallet = Wallet.find_by!(business_id: @current_business.id,  is_test: false)
          wallet_history_id = create_wallet_history(wallet).id
          reference = JsonWebToken.encode({ business_id: @current_business.id, profile_id: profile_id, wallet_history_id: wallet_history_id, amount: create_fundwallet_params[:amount].to_d })
          WalletHistory.find_by!(id: wallet_history_id ).update!(reference_code: reference)
          json_response({
            status: 200,
            data: {
              reference: reference
            },
            message: 'this is your transaction reference, please keep it safe',
            errMessage: nil
          })
        end
      rescue Exception=> e
        raise ExceptionHandler::RegularError, e
      end
    end


    def verify_fund_wallet
      # if ENV['TEST_MODE'] == true
      #   json_response({
      #     status: 200,
      #     data: nil,
      #     message: 'this is your transaction was successful',
      #     errMessage: nil
      #   })
      #   return 
      # end
      if @current_user.profiles.first.test_mode?

        reference = JsonWebToken.decode(get_reference[:reference])
        if reference[:profile_id] == @current_user.profiles.first.id
          begin
            response = RestClient.get("#{ENV.fetch("PAYMENT_VENDOR_URL", "")}/transactions/#{get_reference[:transaction_id]}/verify",
            {accept: :json, :Authorization=> "Bearer #{ENV["PAYMENT_VENDOR_TEST_KEY"] || ENV["PAYMENT_VENDOR_API_KEY"]}"})
            response_body = JSON(response.body)
            if response_body['status'] && (response_body['data']["status"] == "success" || response_body["data"]["status"] == "successful")
              wallet_history = WalletHistory.where(id: reference[:wallet_history_id],  reference_code: get_reference[:reference]).exists?
              if wallet_history
                wallet = Wallet.find_by(business_id: reference[:business_id], is_test: true)
                wallet.update!(is_active: true, available_balance: wallet.available_balance + reference[:amount].to_d, cleared_balance: wallet.cleared_balance + reference[:amount].to_d)
                WalletHistory.find_by(id: reference[:wallet_history_id],  reference_code: get_reference[:reference]).update!(reference_code: nil, status: true, details: response)
                json_response({
                  status: 200,
                  data: nil,
                  message: 'this transaction was successful',
                  errMessage: nil
                })
              else
                json_response({
                  status: 403,
                  data: nil,
                  message: "error",
                  errMessage: "payment record doesn't exist/has been completed!"
                }, :payment_required)
              end
            else
              json_response({
                status: 403,
                data: nil,
                message: "error",
                errMessage: "transaction with reference was not completed"
              }, :payment_required)
            end
  
          rescue RestClient::ExceptionWithResponse => e
            # failure_notifier(response_body, transaction_log, e)
              json_response({
                status: e.http_code,
                data: JSON(e.response),
                message: nil,
                errMessage: e.default_message
              }, e.http_code)
  
          rescue Exception => e
            # failure_notifier(response_body, transaction_log, e)
              json_response({
                  status: 500,
                  data: nil,
                  message: "Error",
                  errMessage: e.message || 'Oops, something went wrong'
              }, :internal_server_error)
          end
        else
          json_response({
            status: 403,
            data: nil,
            message: "Your reference does't match to your profile",
            errMessage: nil
          })
        end

      else
        reference = JsonWebToken.decode(get_reference[:reference])
        if reference[:profile_id] == @current_user.profiles.first.id
          begin
            response = RestClient.get("#{ENV.fetch("PAYMENT_VENDOR_URL", "")}/transactions/#{get_reference[:transaction_id]}/verify",
            {accept: :json, :Authorization=> "Bearer #{ENV["PAYMENT_VENDOR_API_KEY"]}"})
            response_body = JSON(response.body)
            if response_body['status'] && response_body['data']["status"]== "success" || response_body['data']["status"]== "successful"
              wallet_history = WalletHistory.where(id: reference[:wallet_history_id],  reference_code: get_reference[:reference]).exists?
              if wallet_history
                wallet = Wallet.find_by(business_id: reference[:business_id], is_test: false)
                wallet.update!(is_active: true, available_balance: wallet.available_balance + reference[:amount].to_d, cleared_balance: wallet.cleared_balance + reference[:amount].to_d)
                WalletHistory.find_by(id: reference[:wallet_history_id],  reference_code: get_reference[:reference]).update!(reference_code: nil, status: true, details: JSON(response))
                json_response({
                  status: 200,
                  data: nil,
                  message: 'this is your transaction was successful',
                  errMessage: nil
                })
              else
                json_response({
                  status: 403,
                  data: nil,
                  message: "error",
                  errMessage: "payment record doesn't exist/has been completed!"
                }, :payment_required)
              end
            else
              json_response({
                status: 403,
                data: nil,
                message: "error",
                errMessage: "transaction with reference was not completed"
              }, :payment_required)
            end
  
          rescue RestClient::ExceptionWithResponse => e
            # failure_notifier(response_body, nil, e)
              json_response({
                status: e.http_code,
                data: JSON(e.response),
                message: nil,
                errMessage: e.default_message
              }, e.http_code)
  
          rescue Exception => e
            # failure_notifier(response_body, nil, e)
              json_response({
                  status: 500,
                  data: nil,
                  message: "Error",
                  errMessage: e.message || 'Oops, something went wrong'
              }, :internal_server_error)
          end
        else
          json_response({
            status: 403,
            data: nil,
            message: "Your reference does't match to your profile",
            errMessage: nil
          })
        end
      end
    
    end






    def paystack_verify_fund_wallet
      # if ENV['TEST_MODE'] == true
      #   json_response({
      #     status: 200,
      #     data: nil,
      #     message: 'this is your transaction was successful',
      #     errMessage: nil
      #   })
      #   return 
      # end
      if @current_user.profiles.first.test_mode?

        reference = JsonWebToken.decode(get_reference[:reference])
        if reference[:profile_id] == @current_user.profiles.first.id
          begin
            response = RestClient.get("#{ENV.fetch("PAYSTACK_PAYMENT_VENDOR_URL", "")}/transaction/verify/#{get_reference[:reference]}",
            {accept: :json, :Authorization=> "Bearer #{ENV["PAYSTACK_PAYMENT_VENDOR_TEST_KEY"] || ENV["PAYSTACK_PAYMENT_VENDOR_API_KEY"]}"})
            response_body = JSON(response.body)
            if response_body['status'] && response_body['data']["status"]== "success"
              wallet_history = WalletHistory.where(id: reference[:wallet_history_id],  reference_code: get_reference[:reference]).exists?
              if wallet_history
                wallet = Wallet.find_by(business_id: reference[:business_id], is_test: true)
                wallet.update!(is_active: true, available_balance: wallet.available_balance + reference[:amount].to_d, cleared_balance: wallet.cleared_balance + reference[:amount].to_d)
                WalletHistory.find_by(id: reference[:wallet_history_id],  reference_code: get_reference[:reference]).update!(reference_code: nil, status: true, details: response)
                json_response({
                  status: 200,
                  data: nil,
                  message: 'this transaction was successful',
                  errMessage: nil
                })
              else
                json_response({
                  status: 403,
                  data: nil,
                  message: "error",
                  errMessage: "payment record doesn't exist/has been completed!"
                }, :payment_required)
              end
            else
              json_response({
                status: 403,
                data: nil,
                message: "error",
                errMessage: "transaction with reference was not completed"
              }, :payment_required)
            end
  
          rescue RestClient::ExceptionWithResponse => e
            # failure_notifier(response_body, transaction_log, e)
              json_response({
                status: e.http_code,
                data: JSON(e.response),
                message: nil,
                errMessage: e.default_message
              }, e.http_code)
  
          rescue Exception => e
            # failure_notifier(response_body, transaction_log, e)
              json_response({
                  status: 500,
                  data: nil,
                  message: "Error",
                  errMessage: e.message || 'Oops, something went wrong'
              }, :internal_server_error)
          end
        else
          json_response({
            status: 403,
            data: nil,
            message: "Your reference does't match to your profile",
            errMessage: nil
          })
        end

      else
        reference = JsonWebToken.decode(get_reference[:reference])
        if reference[:profile_id] == @current_user.profiles.first.id
          begin
            response = RestClient.get("#{ENV.fetch("PAYSTACK_PAYMENT_VENDOR_URL", "")}/transaction/verify/#{get_reference[:reference]}",
            {accept: :json, :Authorization=> "Bearer #{ENV["PAYSTACK_PAYMENT_VENDOR_API_KEY"]}"})
            response_body = JSON(response.body)
            if response_body['status'] && response_body['data']["status"]== "success" || response_body['data']["status"]== "successful"
              wallet_history = WalletHistory.where(id: reference[:wallet_history_id],  reference_code: get_reference[:reference]).exists?
              if wallet_history
                wallet = Wallet.find_by(business_id: reference[:business_id], is_test: false)
                wallet.update!(is_active: true, available_balance: wallet.available_balance + reference[:amount].to_d, cleared_balance: wallet.cleared_balance + reference[:amount].to_d)
                WalletHistory.find_by(id: reference[:wallet_history_id],  reference_code: get_reference[:reference]).update!(reference_code: nil, status: true, details: JSON(response))
                json_response({
                  status: 200,
                  data: nil,
                  message: 'this is your transaction was successful',
                  errMessage: nil
                })
              else
                json_response({
                  status: 403,
                  data: nil,
                  message: "error",
                  errMessage: "payment record doesn't exist/has been completed!"
                }, :payment_required)
              end
            else
              json_response({
                status: 403,
                data: nil,
                message: "error",
                errMessage: "transaction with reference was not completed"
              }, :payment_required)
            end
  
          rescue RestClient::ExceptionWithResponse => e
            # failure_notifier(response_body, nil, e)
              json_response({
                status: e.http_code,
                data: JSON(e.response),
                message: nil,
                errMessage: e.default_message
              }, e.http_code)
  
          rescue Exception => e
            # failure_notifier(response_body, nil, e)
              json_response({
                  status: 500,
                  data: nil,
                  message: "Error",
                  errMessage: e.message || 'Oops, something went wrong'
              }, :internal_server_error)
          end
        else
          json_response({
            status: 403,
            data: nil,
            message: "Your reference does't match to your profile",
            errMessage: nil
          })
        end
      end
    
    end

    def create_make_transaction
      begin
        if ENV['TEST_MODE'] != "true" || ENV['TEST_MODE'] != true
          profile_id = @current_user.profiles.first.id
          transaction = create_transaction_log("send", "pending", create_transaction_params[:card_code], create_transaction_params[:amount])
          
          winner = PromoWinner.where(profile: @current_user.profiles.first, is_active: true, is_completed: false, is_expired: false, transaction_log_id: nil)
          if winner.exists?
            winner = PromoWinner.find_by!(profile: @current_user.profiles.first, is_active: true, is_completed: false, is_expired: false, transaction_log_id: nil)
            promo = Promo.find(winner.promo_id)
            transaction.update!(is_discounted: true, discount_rate: promo.discount)
            winner.update!(transaction_log_id: transaction.id)
          end

          json_response({
              status: 200,
              data: {
                reference: transaction.reference_id
              },
              message: 'this is your transaction reference, please keep it safe',
              errMessage: nil
            })
        else
          profile_id = @current_user.profiles.first.id
          transaction = create_transaction_log("send", "test", create_transaction_params[:card_code], create_transaction_params[:amount])

          json_response({
              status: 200,
              data: {
                reference: transaction.reference_id
              },
              message: 'this is your transaction reference, please keep it safe',
              errMessage: nil
            })
        end
      rescue Exception => e
        # failure_notifier(response_body, transaction, e)
        raise ExceptionHandler::RegularError, e
      end
      
    end

    def create_new_transaction
      begin
        if ENV['TEST_MODE'] != "true" || ENV['TEST_MODE'] != true
          profile_id = @current_user.profiles.first.id
          transaction = create_transaction_log("send", "pending", create_transaction_params[:card_code], create_transaction_params[:amount])

          winner = PromoWinner.where(profile: @current_user.profiles.first, is_active: true, is_completed: false, is_expired: false, transaction_log_id: nil)
          if winner.exists?
            winner = PromoWinner.find_by!(profile: @current_user.profiles.first, is_active: true, is_completed: false, is_expired: false, transaction_log_id: nil)
            promo = Promo.find(winner.promo_id)
            transaction.update!(is_discounted: true, discount_rate: promo.discount)
            winner.update!(transaction_log_id: transaction.id)
          end

          if create_new_transaction_type[:type] == "airtime"
            transaction.update(log_type: "airtime")
          elsif create_new_transaction_type[:type] == "cabletv"
            transaction.update(log_type: "cabletv")
          elsif create_new_transaction_type[:type] == "electricbill"
            transaction.update(log_type: "electricbill")
          elsif create_new_transaction_type[:type] == "epin"
            transaction.update(log_type: "epin")
          elsif create_new_transaction_type[:type] == "cart"
            raise ExceptionHandler::RegularError, "cart id cannot be empty" unless !create_transaction_params[:cart_id].blank?
            cart = Cart.where(id: create_transaction_params[:cart_id], checked_out: false, is_active: true)
            unless cart.exists?
              transaction.update(status: "failed")
              raise ExceptionHandler::RegularError, "could not find cart"
            end
            transaction.update(cart_id: create_transaction_params[:cart_id])
          else
            json_response({
              status: 422,
              data: nil,
              message: 'error',
              errMessage: "cannot find route type"
            }, :unprocessable_entity)
            return
          end

          json_response({
            status: 200,
            data: {
              reference: transaction.reference_id
            },
            message: 'this is your transaction reference, please keep it safe',
            errMessage: nil
          })
        else
          profile_id = @current_user.profiles.first.id
          transaction = create_transaction_log("send", "test", create_transaction_params[:card_code], create_transaction_params[:amount])


          if create_new_transaction_type[:type] == "cart"
            raise ExceptionHandler::RegularError, "cart id cannot be empty" unless !create_transaction_params[:cart_id].blank?
            cart = Cart.where(id: create_transaction_params[:cart_id], checked_out: false, is_active: true)
            unless cart.exists?
              transaction.update(status: "failed")
              raise ExceptionHandler::RegularError, "could not find cart"
            end
            transaction.update(cart_id: create_transaction_params[:cart_id])
          else
            json_response({
              status: 422,
              data: nil,
              message: 'error',
              errMessage: "cannot find route type"
            }, :unprocessable_entity)
            return
          end

          json_response({
              status: 200,
              data: {
                reference: transaction.reference_id
              },
              message: 'this is your transaction reference, please keep it safe',
              errMessage: nil
            })
        end  
      rescue Exception => e
        # failure_notifier(response_body, transaction, e)
        raise ExceptionHandler::RegularError, e
      end
      
    end

    def create_make_tmp_transaction #tmp transaction reference
      begin
        tmp_user_email = JsonWebToken.decode(request.headers["tmp-token"])
        @current_user = User.find_by(email: tmp_user_email[:email])
        if ENV['TEST_MODE'] != "true" || ENV['TEST_MODE'] != true
          profile_id = @current_user.profiles.first.id
          transaction = create_transaction_log("send", "pending", create_transaction_params[:card_code], create_transaction_params[:amount])
          json_response({
              status: 200,
              data: {
                reference: transaction.reference_id
              },
              message: 'this is your transaction reference, please keep it safe',
              errMessage: nil
            })
        else
          profile_id = @current_user.profiles.first.id
          transaction = create_transaction_log("send", "test", create_transaction_params[:card_code], create_transaction_params[:amount])
          json_response({
              status: 200,
              data: {
                reference: transaction.reference_id
              },
              message: 'this is your transaction reference, please keep it safe',
              errMessage: nil
            })
        end
      rescue Exception => e
        # failure_notifier(response_body, transaction, e)
        json_response({
              status: 401,
              data: nil,
              message: 'This request is unauthorized. Please confirm your email to continue this process',
              errMessage: e.message || 'Oops, something went wrong'
            }, :unauthorized)
      end
    end



    def verify_make_transaction
      begin
        if ENV['TEST_MODE'] != "true" || ENV['TEST_MODE'] != true
          response = RestClient.get("#{ENV.fetch("PAYMENT_VENDOR_URL", "")}/transactions/#{get_reference[:transaction_id]}/verify",
                {accept: :json, :Authorization=> "Bearer #{ENV["PAYMENT_VENDOR_API_KEY"]}"})
          response_body = JSON(response.body)
          reference_id = response_body['data']['tx_ref']
          
          if response_body['status'] && (response_body['data']["status"] == "success" || response_body['data']["status"] == "successful")
            transaction_log = TransactionLog.where(reference_id: reference_id, status: 'pending')
            if transaction_log.exists?
              transaction_log = TransactionLog.find_by!(reference_id: reference_id, status: 'pending')
            
                if transaction_log.is_discounted == true
                  calc_value = ((transaction_log.amount.try(:to_f)) * (transaction_log.discount_rate.try(:to_f))).ceil
                  if response_body['data']["amount"] != calc_value
                    transaction_log.update!(status: 'failed', details: { payment: JSON(response) })
                    raise ExceptionHandler::RegularError, "payment amount does't match reference amount"
                  end
                else
                  if response_body['data']["amount"] != (transaction_log.amount.try(:to_f)).ceil
                    transaction_log.update!(status: 'failed', details: { payment: JSON(response) })
                    raise ExceptionHandler::RegularError, "payment amount does't match reference amount"
                  end
                end

                transaction_log.update!(status: 'success', details: { payment: JSON(response) })
              json_response({
                status: 200,
                data: nil,
                message: 'this transaction was successful',
                errMessage: nil
              })
            else
              json_response({
                status: 403,
                data: nil,
                message: "error",
                errMessage: "payment record doesn't exist/has been completed!"
              }, :payment_required)
            end
          else
            json_response({
              status: 403,
              data: nil,
              message: "error",
              errMessage: "transaction with reference was not completed"
            }, :payment_required)
          end
              
        else
          response = RestClient.get("#{ENV.fetch("PAYMENT_VENDOR_URL", "")}/transactions/#{get_reference[:transaction_id]}/verify",
                {accept: :json, :Authorization=> "Bearer #{ENV["PAYMENT_VENDOR_TEST_KEY"]|| ENV["PAYMENT_VENDOR_API_KEY"]}"})
          response_body = JSON(response.body)
          reference_id = response_body['data']['tx_ref']
          if response_body['status'] && (response_body['data']["status"] == "success" || response_body['data']["status"] == "successful")
            transaction_log = TransactionLog.where(reference_id: reference_id, status: 'test')
            if transaction_log.exists?
              transaction_log = TransactionLog.find_by!(reference_id: reference_id, status: 'pending')
              if response_body['data']["amount"] != (transaction_log.amount.try(:to_f))
                raise ExceptionHandler::RegularError, "payment amount does't much reference amount"
              end

              transaction_log.update!(details: { payment: JSON(response) })
                # TransactionLog.find_by!(reference_id: get_reference[:reference]).update!(details: { payment: JSON(response) })
              json_response({
                status: 200,
                data: nil,
                message: 'this is your transaction was successful',
                errMessage: nil
              })
            else
              json_response({
                status: 403,
                data: nil,
                message: "error",
                errMessage: "payment record doesn't exist/has been completed!"
              }, :payment_required)
            end
          else
            json_response({
              status: 403,
              data: nil,
              message: "error",
              errMessage: "transaction with reference was not completed"
            }, :payment_required)
          end   
        end
      rescue RestClient::ExceptionWithResponse => e
        # failure_notifier(response_body, transaction_log, e)
        # data = JSON(e.response)
          json_response({
            status: e.http_code,
            data: e.response,
            message: nil,
            errMessage: e.default_message || e.message || 'Oops, something went wrong'
          }, e.http_code)

      rescue Exception => e
        # failure_notifier(response_body, transaction_log, e)
          json_response({
              status: 500,
              data: nil,
              message: "Error",
              errMessage: e.message || 'Oops, something went wrong'
            }, :internal_server_error)
      end
    end
    

    def paystack_verify_make_transaction
      begin
        if ENV['TEST_MODE'] != "true" || ENV['TEST_MODE'] != true
          response = RestClient.get("#{ENV.fetch("PAYSTACK_PAYMENT_VENDOR_URL", "")}/transaction/verify/#{get_reference[:reference]}",
                {accept: :json, :Authorization=> "Bearer #{ENV["PAYSTACK_PAYMENT_VENDOR_API_KEY"]}"})
          response_body = JSON(response.body)
          
          if response_body['status'] && response_body['data']["status"] == "success"
            transaction_log = TransactionLog.where(reference_id: get_reference[:reference], status: 'pending')
            if transaction_log.exists?
              transaction_log = TransactionLog.find_by!(reference_id: get_reference[:reference], status: 'pending')
            
                if transaction_log.is_discounted == true
                  calc_value = ((transaction_log.amount.try(:to_f) * 100) * (transaction_log.discount_rate.try(:to_f))).ceil
                  if response_body['data']["amount"] != calc_value
                    transaction_log.update!(status: 'failed', details: { payment: JSON(response) })
                    raise ExceptionHandler::RegularError, "payment amount does't match reference amount"
                  end
                else
                  if response_body['data']["amount"] != (transaction_log.amount.try(:to_f) * 100).ceil
                    transaction_log.update!(status: 'failed', details: { payment: JSON(response) })
                    raise ExceptionHandler::RegularError, "payment amount does't match reference amount"
                  end
                end

                transaction_log.update!(status: 'success', details: { payment: JSON(response) })
              json_response({
                status: 200,
                data: nil,
                message: 'this transaction was successful',
                errMessage: nil
              })
            else
              json_response({
                status: 403,
                data: nil,
                message: "error",
                errMessage: "payment record doesn't exist/has been completed!"
              }, :payment_required)
            end
          else
            json_response({
              status: 403,
              data: nil,
              message: "error",
              errMessage: "transaction with reference was not completed"
            }, :payment_required)
          end
              
        else
          response = RestClient.get("#{ENV.fetch("PAYSTACK_PAYMENT_VENDOR_URL", "")}/transaction/verify/#{get_reference[:reference]}",
                {accept: :json, :Authorization=> "Bearer #{ENV["PAYSTACK_PAYMENT_VENDOR_TEST_KEY"]|| ENV["PAYSTACK_PAYMENT_VENDOR_API_KEY"]}"})
          response_body = JSON(response.body)
          if response_body['status'] && response_body['data']["status"]== "success"
            transaction_log = TransactionLog.where(reference_id: get_reference[:reference], status: 'test')
            if transaction_log.exists?
              transaction_log = TransactionLog.find_by!(reference_id: get_reference[:reference], status: 'pending')
              if response_body['data']["amount"] != (transaction_log.amount.try(:to_f) * 100)
                raise ExceptionHandler::RegularError, "payment amount does't much reference amount"
              end

              transaction_log.update!(details: { payment: JSON(response) })
                # TransactionLog.find_by!(reference_id: get_reference[:reference]).update!(details: { payment: JSON(response) })
              json_response({
                status: 200,
                data: nil,
                message: 'this is your transaction was successful',
                errMessage: nil
              })
            else
              json_response({
                status: 403,
                data: nil,
                message: "error",
                errMessage: "payment record doesn't exist/has been completed!"
              }, :payment_required)
            end
          else
            json_response({
              status: 403,
              data: nil,
              message: "error",
              errMessage: "transaction with reference was not completed"
            }, :payment_required)
          end   
        end
      rescue RestClient::ExceptionWithResponse => e
        # failure_notifier(response_body, transaction_log, e)
        data = JSON(e.response)
          json_response({
            status: e.http_code,
            data: data,
            message: nil,
            errMessage: data.try(:[], "message")|| e.default_message || e.message || 'Oops, something went wrong'
          }, e.http_code)

      rescue Exception => e
        # failure_notifier(response_body, transaction_log, e)
          json_response({
              status: 500,
              data: nil,
              message: "Error",
              errMessage: e.message || 'Oops, something went wrong'
            }, :internal_server_error)
      end
    end
    



    def cancel_make_transaction
      begin
        if ENV['TEST_MODE'] != "true" || ENV['TEST_MODE'] != true
          response = RestClient.get("#{ENV.fetch("PAYMENT_VENDOR_URL", "")}/transactions/#{get_reference[:transaction_id]}/verify",
                {accept: :json, :Authorization=> "Bearer #{ENV["PAYMENT_VENDOR_API_KEY"]}"})
          response_body = JSON(response.body)
          if response_body['status'] && response_body['data']["status"] == "abandoned"
            transaction_log = TransactionLog.where(reference_id: get_reference[:reference], status: 'pending').exists?
            if transaction_log
              transaction_log = TransactionLog.find_by!(reference_id: get_reference[:reference], status: 'pending')
              transaction_log.update!(status: 'abandoned', details: { payment: JSON(response) })


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
                    if PromoWinner.where(transaction_log_id: transaction_log.id).exists?
                      PromoWinner.find_by(transaction_log_id: transaction_log.id).update!(is_expired: true)
                    end
                  end
                end

                TransactionLog.find_by!(reference_id: get_reference[:reference], status: 'pending').update!(status: 'failed', details: { payment: JSON(response) })

                # failure_notifier(response_body, transaction_log, "this transaction has being abandoned")

              json_response({
                status: 200,
                data: nil,
                message: 'this transaction has being abandoned',
                errMessage: nil
              })
            elsif TransactionLog.where(reference_id: get_reference[:reference], status: 'failed').exists?

              transaction_log = TransactionLog.find_by!(reference_id: get_reference[:reference], status: 'failed')
              
                promo = Promo.where(is_active: true)
                if promo.exists? || (ENV["DISCOUNT_PERIOD"] == 'true' || ENV["DISCOUNT_PERIOD"] == true)
                  promo = Promo.find_by(is_active: true)
                  if promo.current_count >= promo.final_count
                    promo.update!(current_count: 1)
                    if PromoWinner.where(transaction_log_id: transaction_log.id).exists?
                      PromoWinner.find_by(transaction_log_id: transaction_log.id).update!(is_expired: true)
                    end
                  else
                    promo = Promo.where(is_active: true)
                    if promo.exists?
                      promo = Promo.find_by(is_active: true)
                      promo.update!(current_count: (promo.current_count + 1))
                    end
                    if PromoWinner.where(transaction_log_id: transaction_log.id).exists?
                      PromoWinner.find_by(transaction_log_id: transaction_log.id).update!(is_expired: true)
                    end
                  end
                end

              # if ENV['RAILS_ENV'] != 'production'
              #   SendUserDropoffNotificationJob.perform_now(@current_user, transaction, "this transaction was abandoned")
              # else
              #   SendUserDropoffNotificationJob.perform_later(@current_user, transaction, "this transaction was abandoned")
              # end
              # failure_notifier(response_body, transaction_log, "this transaction was abandoned")
              json_response({
                status: 403,
                data: nil,
                message: "error",
                errMessage: "this transaction was abandoned"
              }, :payment_required)
            else
              # if ENV['RAILS_ENV'] != 'production'
              #   SendUserDropoffNotificationJob.perform_now(@current_user, transaction, "payment record doesn't exist/has been completed!")
              # else
              #   SendUserDropoffNotificationJob.perform_later(@current_user, transaction, "payment record doesn't exist/has been completed!")
              # end
              # failure_notifier(response_body, transaction_log, "payment record doesn't exist/has been completed!")
              json_response({
                status: 403,
                data: nil,
                message: "error",
                errMessage: "payment record doesn't exist/has been completed!"
              }, :payment_required)
            end
            
          elsif response_body['status'] && response_body['data']["status"] == "success"
            json_response({
              status: 403,
              data: nil,
              message: "error",
              errMessage: "this payment has been completed!"
            }, :payment_required)
          else
            json_response({
              status: 403,
              data: nil,
              message: "error",
              errMessage: "transaction with reference not found"
            }, :payment_required)
          end
              
        else
          response = RestClient.get("#{ENV.fetch("PAYMENT_VENDOR_URL", "")}/transactions/#{get_reference[:transaction_id]}/verify}",
                {accept: :json, :Authorization=> "Bearer #{ENV["PAYMENT_VENDOR_TEST_KEY"]|| ENV["PAYMENT_VENDOR_API_KEY"]}"})
          response_body = JSON(response.body)
          if response_body['status'] && response_body['data']["status"]== "abandoned"
            transaction_log = TransactionLog.where(reference_id: get_reference[:reference], status: 'test').exists?
            if transaction_log
                TransactionLog.find_by!(reference_id: get_reference[:reference]).update!(status: 'abandoned', details: { payment: JSON(response) })
                if ENV['RAILS_ENV'] != 'production'
                  SendUserDropoffNotificationJob.perform_now(@current_user, transaction, "this transaction has being abandoned")
                else
                  SendUserDropoffNotificationJob.perform_later(@current_user, transaction, "this transaction has being abandoned")
                end
              json_response({
                status: 200,
                data: nil,
                message: 'this transaction has being abandoned',
                errMessage: nil
              })

            elsif TransactionLog.where(reference_id: get_reference[:reference], status: 'failed').exists?
              if ENV['RAILS_ENV'] != 'production'
                SendUserDropoffNotificationJob.perform_now(@current_user, transaction, "this transaction was abandoned")
              else
                SendUserDropoffNotificationJob.perform_later(@current_user, transaction, "this transaction was abandoned")
              end
              json_response({
                status: 403,
                data: nil,
                message: "error",
                errMessage: "this transaction was abandoned"
              }, :payment_required)
            else
              if ENV['RAILS_ENV'] != 'production'
                SendUserDropoffNotificationJob.perform_now(@current_user, transaction, "test payment record doesn't exist/has been completed!")
              else
                SendUserDropoffNotificationJob.perform_later(@current_user, transaction, "test payment record doesn't exist/has been completed!")
              end
              json_response({
                status: 403,
                data: nil,
                message: "error",
                errMessage: "test payment record doesn't exist/has been completed!"
              }, :payment_required)
            end
          elsif response_body['status'] && response_body['data']["status"] == "success"
            json_response({
              status: 403,
              data: nil,
              message: "error",
              errMessage: "this payment has been completed!"
            }, :payment_required)
          else
            if ENV['RAILS_ENV'] != 'production'
              SendUserDropoffNotificationJob.perform_now(@current_user, transaction, "transaction with reference not found")
            else
              SendUserDropoffNotificationJob.perform_later(@current_user, transaction, "transaction with reference not found")
            end
            json_response({
              status: 403,
              data: nil,
              message: "error",
              errMessage: "transaction with reference not found"
            }, :payment_required)
          end
        end
      rescue RestClient::ExceptionWithResponse => e
          if ENV['RAILS_ENV'] != 'production'
            SendUserDropoffNotificationJob.perform_now(@current_user, transaction, e.default_message)
          else
            SendUserDropoffNotificationJob.perform_later(@current_user, transaction, e.default_message)
          end
          json_response({
            status: e.http_code,
            data: JSON(e.response),
            message: nil,
            errMessage: e.default_message
          }, e.http_code)

      rescue Exception => e
          if ENV['RAILS_ENV'] != 'production'
            SendUserDropoffNotificationJob.perform_now(@current_user, transaction, 'Oops, something went wrong')
          else
            SendUserDropoffNotificationJob.perform_later(@current_user, transaction, 'Oops, something went wrong')
          end
          json_response({
              status: 500,
              data: nil,
              message: "Error",
              errMessage: e.message || 'Oops, something went wrong'
            }, :internal_server_error)
      ensure
        if ENV['RAILS_ENV'] != 'production'
          SendUserDropoffNotificationJob.perform_now(@current_user, transaction, 'This transaction was canceled')
        else
          SendUserDropoffNotificationJob.perform_later(@current_user, transaction, 'This transaction was canceled')
        end
      end
    end





    def paystack_cancel_make_transaction
      begin
        if ENV['TEST_MODE'] != "true" || ENV['TEST_MODE'] != true
          response = RestClient.get("#{ENV.fetch("PAYMENT_VENDOR_URL", "")}/transaction/verify/#{get_reference[:reference]}",
                {accept: :json, :Authorization=> "Bearer #{ENV["PAYMENT_VENDOR_API_KEY"]}"})
          response_body = JSON(response.body)
          if response_body['status'] && response_body['data']["status"] == "abandoned"
            transaction_log = TransactionLog.where(reference_id: get_reference[:reference], status: 'pending').exists?
            if transaction_log
              transaction_log = TransactionLog.find_by!(reference_id: get_reference[:reference], status: 'pending')
              transaction_log.update!(status: 'abandoned', details: { payment: JSON(response) })


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
                    if PromoWinner.where(transaction_log_id: transaction_log.id).exists?
                      PromoWinner.find_by(transaction_log_id: transaction_log.id).update!(is_expired: true)
                    end
                  end
                end

                TransactionLog.find_by!(reference_id: get_reference[:reference], status: 'pending').update!(status: 'failed', details: { payment: JSON(response) })

                # failure_notifier(response_body, transaction_log, "this transaction has being abandoned")

              json_response({
                status: 200,
                data: nil,
                message: 'this transaction has being abandoned',
                errMessage: nil
              })
            elsif TransactionLog.where(reference_id: get_reference[:reference], status: 'failed').exists?

              transaction_log = TransactionLog.find_by!(reference_id: get_reference[:reference], status: 'failed')
              
                promo = Promo.where(is_active: true)
                if promo.exists? || (ENV["DISCOUNT_PERIOD"] == 'true' || ENV["DISCOUNT_PERIOD"] == true)
                  promo = Promo.find_by(is_active: true)
                  if promo.current_count >= promo.final_count
                    promo.update!(current_count: 1)
                    if PromoWinner.where(transaction_log_id: transaction_log.id).exists?
                      PromoWinner.find_by(transaction_log_id: transaction_log.id).update!(is_expired: true)
                    end
                  else
                    promo = Promo.where(is_active: true)
                    if promo.exists?
                      promo = Promo.find_by(is_active: true)
                      promo.update!(current_count: (promo.current_count + 1))
                    end
                    if PromoWinner.where(transaction_log_id: transaction_log.id).exists?
                      PromoWinner.find_by(transaction_log_id: transaction_log.id).update!(is_expired: true)
                    end
                  end
                end

              # if ENV['RAILS_ENV'] != 'production'
              #   SendUserDropoffNotificationJob.perform_now(@current_user, transaction, "this transaction was abandoned")
              # else
              #   SendUserDropoffNotificationJob.perform_later(@current_user, transaction, "this transaction was abandoned")
              # end
              # failure_notifier(response_body, transaction_log, "this transaction was abandoned")
              json_response({
                status: 403,
                data: nil,
                message: "error",
                errMessage: "this transaction was abandoned"
              }, :payment_required)
            else
              # if ENV['RAILS_ENV'] != 'production'
              #   SendUserDropoffNotificationJob.perform_now(@current_user, transaction, "payment record doesn't exist/has been completed!")
              # else
              #   SendUserDropoffNotificationJob.perform_later(@current_user, transaction, "payment record doesn't exist/has been completed!")
              # end
              # failure_notifier(response_body, transaction_log, "payment record doesn't exist/has been completed!")
              json_response({
                status: 403,
                data: nil,
                message: "error",
                errMessage: "payment record doesn't exist/has been completed!"
              }, :payment_required)
            end
            
          elsif response_body['status'] && response_body['data']["status"] == "success"
            json_response({
              status: 403,
              data: nil,
              message: "error",
              errMessage: "this payment has been completed!"
            }, :payment_required)
          else
            json_response({
              status: 403,
              data: nil,
              message: "error",
              errMessage: "transaction with reference not found"
            }, :payment_required)
          end
              
        else
          response = RestClient.get("#{ENV.fetch("PAYMENT_VENDOR_URL", "")}/transaction/verify/#{get_reference[:reference]}",
                {accept: :json, :Authorization=> "Bearer #{ENV["PAYMENT_VENDOR_TEST_KEY"]|| ENV["PAYMENT_VENDOR_API_KEY"]}"})
          response_body = JSON(response.body)
          if response_body['status'] && response_body['data']["status"]== "abandoned"
            transaction_log = TransactionLog.where(reference_id: get_reference[:reference], status: 'test').exists?
            if transaction_log
                TransactionLog.find_by!(reference_id: get_reference[:reference]).update!(status: 'abandoned', details: { payment: JSON(response) })
                if ENV['RAILS_ENV'] != 'production'
                  SendUserDropoffNotificationJob.perform_now(@current_user, transaction, "this transaction has being abandoned")
                else
                  SendUserDropoffNotificationJob.perform_later(@current_user, transaction, "this transaction has being abandoned")
                end
              json_response({
                status: 200,
                data: nil,
                message: 'this transaction has being abandoned',
                errMessage: nil
              })

            elsif TransactionLog.where(reference_id: get_reference[:reference], status: 'failed').exists?
              if ENV['RAILS_ENV'] != 'production'
                SendUserDropoffNotificationJob.perform_now(@current_user, transaction, "this transaction was abandoned")
              else
                SendUserDropoffNotificationJob.perform_later(@current_user, transaction, "this transaction was abandoned")
              end
              json_response({
                status: 403,
                data: nil,
                message: "error",
                errMessage: "this transaction was abandoned"
              }, :payment_required)
            else
              if ENV['RAILS_ENV'] != 'production'
                SendUserDropoffNotificationJob.perform_now(@current_user, transaction, "test payment record doesn't exist/has been completed!")
              else
                SendUserDropoffNotificationJob.perform_later(@current_user, transaction, "test payment record doesn't exist/has been completed!")
              end
              json_response({
                status: 403,
                data: nil,
                message: "error",
                errMessage: "test payment record doesn't exist/has been completed!"
              }, :payment_required)
            end
          elsif response_body['status'] && response_body['data']["status"] == "success"
            json_response({
              status: 403,
              data: nil,
              message: "error",
              errMessage: "this payment has been completed!"
            }, :payment_required)
          else
            if ENV['RAILS_ENV'] != 'production'
              SendUserDropoffNotificationJob.perform_now(@current_user, transaction, "transaction with reference not found")
            else
              SendUserDropoffNotificationJob.perform_later(@current_user, transaction, "transaction with reference not found")
            end
            json_response({
              status: 403,
              data: nil,
              message: "error",
              errMessage: "transaction with reference not found"
            }, :payment_required)
          end
        end
      rescue RestClient::ExceptionWithResponse => e
          if ENV['RAILS_ENV'] != 'production'
            SendUserDropoffNotificationJob.perform_now(@current_user, transaction, e.default_message)
          else
            SendUserDropoffNotificationJob.perform_later(@current_user, transaction, e.default_message)
          end
          json_response({
            status: e.http_code,
            data: JSON(e.response),
            message: nil,
            errMessage: e.default_message
          }, e.http_code)

      rescue Exception => e
          if ENV['RAILS_ENV'] != 'production'
            SendUserDropoffNotificationJob.perform_now(@current_user, transaction, 'Oops, something went wrong')
          else
            SendUserDropoffNotificationJob.perform_later(@current_user, transaction, 'Oops, something went wrong')
          end
          json_response({
              status: 500,
              data: nil,
              message: "Error",
              errMessage: e.message || 'Oops, something went wrong'
            }, :internal_server_error)
      ensure
        if ENV['RAILS_ENV'] != 'production'
          SendUserDropoffNotificationJob.perform_now(@current_user, transaction, 'This transaction was canceled')
        else
          SendUserDropoffNotificationJob.perform_later(@current_user, transaction, 'This transaction was canceled')
        end
      end
    end

    def fetch_send_transactions
      transaction_logs = []

      begin
        if @current_user.profiles.first.profile_type == 'personal'
          TransactionLog.find_each do |transaction_log|
            transaction_logs << transaction_log if transaction_log.profile_id == @current_user.profiles.first.id && transaction_log.status != 'test'
          end
        else
          if @current_user.profiles.first.test_mode == false
            TransactionLog.find_each do |transaction_log|
              transaction_logs << transaction_log if transaction_log.profile_id == @current_user.profiles.first.id && transaction_log.status != 'test'
            end
          else
            TransactionLog.find_each do |transaction_log|
              transaction_logs << transaction_log if transaction_log.profile_id == @current_user.profiles.first.id && transaction_log.status == 'test'
            end
          end
        end
        if !params[:per_page].blank?
          transaction_logs = Kaminari.paginate_array(transaction_logs.sort!{ |a,b|   b.created_at <=> a.created_at }).page(params[:page]).per(params[:per_page])
        else
          transaction_logs = Kaminari.paginate_array(transaction_logs.sort!{ |a,b|   b.created_at <=> a.created_at }).page(params[:page])
        end

        total = transaction_logs.total_count
        page_count = transaction_logs.total_pages  
        per_page = transaction_logs.limit_value 
        current_page = transaction_logs.current_page
        next_page = transaction_logs.next_page
        prev_page = transaction_logs.prev_page
        first_page = transaction_logs.first_page?
        last_page = transaction_logs.last_page?


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
            data: ActiveModelSerializers::SerializableResource.new(transaction_logs, each_serializer: TransactionLogSerializer)
          },
          message: "all transatcions",
          errMessage: nil
        })
      rescue Exception => e
        raise ExceptionHandler::RegularError, e
      end
    end

    def get_promo_winner
      # begin
        @count= nil
        @title = nil
        @discount = nil
        promo = Promo.where(is_active: true)
        if promo.exists? || (ENV['DISCOUNT_PERIOD'] == 'true' || ENV['DISCOUNT_PERIOD'] == true)
          promo = Promo.where(is_active: true)
          if promo.exists?
            promo = Promo.find_by!(is_active: true)
          else
            promo = Promo.create!(current_count: 1, final_count: ENV['DISCOUNT_COUNT'].try(:to_i) || 1, title: ENV["DISCOUNT_PROMO"] || "black friday promo", discount: ENV["DISCOUNT_RATE"] || '0.5', is_active: true)
          end
         
          if promo.final_count == promo.current_count || ENV['DISCOUNT_COUNT'].try(:to_i) == promo.current_count
            promoWinner = PromoWinner.where({ promo_id: promo.id, is_active: true, is_expired: false, is_completed: false })
            @count = promo.current_count || ENV['DISCOUNT_COUNT']
            @title =  promo.title || ENV["DISCOUNT_PROMO"]
            @discount = promo.discount || ENV["DISCOUNT_RATE"]
            if promoWinner.exists?
              json_response({
                status: 400,
                data: {
                  count: @count,
                  discount: @discount,
                  title: @title
                },
                message: "current user count",
                errMessage: "sorry we currently have a pending winner"
              }, :bad_request)
              return
            end


            PromoWinner.create!(profile: @current_user.profiles.first, promo: promo, is_active: true)


            json_response({
              status: 200,
              data: {
                count: @count,
                discount: @discount,
                title: @title
              },
              message: "Congratulations! you're customer #{ @count } and winner of our #{ @title } event",
              errMessage: nil
            })
            return
          end
          json_response({
            status: 401,
            data: {
              count: @count,
              discount: @discount,
              title: @title
            },
            message: "current user count",
            errMessage: "sorry you aren't our winner"
          }, :unauthorized)
        else
          json_response({
            status: 401,
            data: nil,
            message: "No active Events Found",
            errMessage: nil
          }, :unauthorized)
        end
      # rescue => e
      #   raise ExceptionHandler::RegularError, e
      # end
    end

    protected

    def create_wallet_history(wallet, category = "FUND_WALLET", amount = create_fundwallet_params[:amount])
      available_balance = wallet.available_balance
      actual_amount = available_balance + amount
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
        actual_amount: actual_amount,
        description: '',
        reference_code: '',
        status: false,
        is_active: true
      )
    end



    def create_transaction_log(transaction_type, status, gift_card_code, amount, unique_card_order_id=nil, wallet=nil, wallet_history=nil)
      transaction_rate = Fx.find_by("currency = ? OR name = ?", ENV['FX_CURRENCY'],  'naira')
      TransactionLog.create!(
          wallet: wallet,
          wallet_history: wallet_history,
          reference_id: unique_card_order_id || generate_ref_id,
          profile_id: @current_user.profiles.first.id,
          gift_card_code: gift_card_code,
          log_type: transaction_type,
          status: status,
          is_active: false,
          amount: amount,
          transaction_rate: transaction_rate,
          details: {}
      )
    end
    

    def validate_personal_user!
        raise(ExceptionHandler::InvalidProfileType, 'unauthorized') if @current_user.profiles.first.profile_type == 'business'
    end
    
    def validate_business_user!
      raise(ExceptionHandler::InvalidProfileType, 'unauthorized') if @current_user.profiles.first.profile_type == 'personal'
    end


    private 
    def create_fundwallet_params
        params.permit(
          :amount
        )
    end


    def create_new_transaction_type
      params.permit(
        :type
      )
    end

    def get_reference
      params.permit(
        :reference,
        :transaction_id
      )
    end


    def create_transaction_params
      params.permit(
        :amount,
        :card_code,
        :cart_id,
      )
    end

    def failure_notifier(payload=nil, transaction=nil, err=nil)
      if ENV['RAILS_ENV'] != 'production'
        SendUserDropoffNotificationJob.perform_now(@current_user, transaction, err, payload)
      else
        SendUserDropoffNotificationJob.perform_later(@current_user, transaction, err, payload)
      end
    end

end