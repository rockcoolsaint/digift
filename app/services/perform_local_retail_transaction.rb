class PerformLocalRetailTransaction
    # include Response

    def initialize(current_user:, transaction_type:, transaction_log:, data:, total_amount:, gift_card_name:"")
        @current_user = current_user
        @transaction_type = transaction_type
        @transaction_log = transaction_log
        @data = data
        @total_amount = total_amount
        @gift_card_name = gift_card_name
    end

    def execute!
        card_response = []
        card = @data[:card]
        reference_id = @data[:reference]
        order_id = card[:order_id] || generate_ref_id
        @response= nil
        res = Concurrent::Future.execute do
            # some parallel work

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


            if @data[:cards] && @data[:cards].length
                completed=[]
                @data[:cards].each do |card|
                    ActiveRecord::Base.transaction do
                        # wallet_history = create_wallet_history(@wallet, @transaction_type, card[:dest], card[:amount], 'gift_card')
    
                        # transaction = create_transaction(@wallet, wallet_history, @transaction_type, 'pending', card[:code], card[:order_id])
    
                        # if @transaction_type == "send"
                        #     @wallet.update!(available_balance: @wallet.available_balance - total_amount(card[:dest], card[:amount]))
                        # end

                        dest = [].fill(@data[:dest] || ENV['MAIL_FROM'], 0..(card[:quantity].to_i - 1)).join(";")
                        order_id = card[:order_id] || generate_ref_id
                        payload = {
                            "SendEmail": false,
                            "DeliveryDate": "#{DateTime.now()}",
                            "OrderItemRequests": [{
                                "MerchantId": card[:code] || card[:card_code],
                                "TemplateId": "6D1BB728-4D6B-4A0E-9746-25AF8B1CC57F",
                                "EventName": "Giftcards",
                                "Amount": card[:amount] || card[:value],
                                "Quantity": 1,
                                "RecipientEmail": "#{@data[:dest] || ENV['MAIL_FROM']}",
                                "RecipientPhone": "#{@data[:from]}",
                                "RecipientFirstName": "#{@current_user.profile.first_name}",
                                "RecipientLastName": "#{@current_user.profile.last_name}"
                            }]
                        }
                        begin
                            @response = RestClient.post("#{ENV['SUREGIFTS_API_V1']}/JSONProcessBulkOrder",
                                payload.to_json,
                                {content_type: :json, accept: :json}
                            )
                        rescue RestClient::Exceptions::OpenTimeout => e
                            raise(ExceptionHandler::RestClientExceptionsOpenTimeout, e)
        
                        rescue RestClient::ExceptionWithResponse => e
                            raise(ExceptionHandler::RestClientExceptionWithResponse, e)
        
                        rescue Exception => e
                            raise(ExceptionHandler::RegularError, e)
                        end
    
                        # if(JSON.parse(response.body)["d"]["status"] == true)
                        #     transaction.success!
                        #     wallet_history.update_attribute(:status, true)
                        # else
                        #     transaction.failed!
                        #     wallet_history.update_attribute(:status, false)
                        # end
    
                        # card_response << JSON.parse(response.body)["d"]



                        if (JSON.parse(@response.body)["StatusCode"] == "00")
                            create_order(@transaction_log, order_id, (card[:amount] || card[:value]), (card[:code] || card[:card_code]), JSON.parse(@response.body)["d"], card[:quantity])
                            CartItem.find(card[:id]).update(checked_out: true)
                            completed << card
                        end
                        
                        card_response << JSON.parse(@response.body)["d"]
                        JSON.parse(@response.body)["d"]
                    end
                end
                if @data[:cards].length == completed.length
                    @transaction_log.update!(details: @transaction_log.details.merge({data: JSON.parse(@response.body), payload: payload}), status: 'delivered', is_active: true, gift_card_name: @gift_card_name)
                    Cart.find(@transaction_log.cart_id).update(checked_out: true)
                else
                    @transaction_log.update!(details: @transaction_log.details.merge({data: JSON.parse(@response.body), payload: payload}), gift_card_name: @gift_card_name)
                    @transaction_log.failed!
                end
            else
                ActiveRecord::Base.transaction do
                    payload = {
                        "SendEmail": false,
                        "DeliveryDate": "#{DateTime.now()}",
                        "OrderItemRequests": [{
                            "MerchantId": card[:code][4..].to_i || card[:card_code],
                            "EventName": "Giftcards",
                            "Amount": card[:amount] || card[:value],
                            "Quantity": 1,
                            "RecipientEmail": "#{@data[:dest] || ENV['MAIL_FROM']}",
                            "RecipientPhone": "#{@data[:from]}",
                            "RecipientFirstName": "#{@data[:first_name] || @current_user.profiles.first.first_name}",
                            "RecipientLastName": "#{@data[:last_name] || @current_user.profiles.first.last_name}"
                        }]
                    }
                    begin
                        @response = RestClient.post("#{ENV['SUREGIFTS_API_V1']}/JSONProcessBulkOrder",
                           payload.to_json,
                            {Authorization: "Basic " + Base64::encode64("#{ENV['SUREGIFTS_USERNAME']}:#{ENV['SUREGIFTS_PASSWORD']}"), content_type: :json, accept: :json}
                        )
                    rescue RestClient::Exceptions::OpenTimeout => e
                        raise(ExceptionHandler::RestClientExceptionsOpenTimeout, e)
    
                    rescue RestClient::ExceptionWithResponse => e
                        raise(ExceptionHandler::RestClientExceptionWithResponse, e)
    
                    rescue Exception => e
                        raise(ExceptionHandler::RegularError, e)
                    end

                    if(JSON.parse(@response.body)["StatusCode"] == "00")
                        @transaction_log.update!(details: @transaction_log.details.merge({data: JSON.parse(@response.body), payload: payload}), status: 'delivered', is_active: true, gift_card_name: @gift_card_name)
                        create_order(@transaction_log, order_id, card[:amount], card[:code], JSON.parse(@response.body))
                    else
                        @transaction_log.update!(details: @transaction_log.details.merge({data: JSON.parse(@response.body), payload: payload}), gift_card_name: @gift_card_name)
                        @transaction_log.failed!
                        raise(ExceptionHandler::RegularError, "failed to purchase #{@gift_card_name} giftcard, please contact support for help")
                    end

                    card_response << JSON.parse(@response.body)
                    JSON.parse(@response.body)
                end
            end
            sanitize_response(card_response, @total_amount)
        end
        res.value!
    end

    private

    def create_order(transaction_log, unique_card_order_id, amount, gift_card_code, response, quantity=1)
        profile = get_profile
        Order.create!(
            profile: profile,
            transaction_log: transaction_log,
            card_order_id: unique_card_order_id || generate_ref_id,
            total_amount: @total_amount,
            amount: amount,
            quantity: quantity,
            gift_card_code: gift_card_code,
            details: response,
            order_type: 'send',
            status: 'success',
            is_active: true
        )
    end

    def generate_ref_id
        loop do
          uuid = SecureRandom.uuid
          break uuid unless TransactionLog.find_by(reference_id: uuid)
        end
    end

    def sanitize_response(card_response, amount)
        card_response.map do |response|
            response.each do |k, v|
                if response[k].respond_to? :to_ary
                   if response[k] && response[k].length
                    response[k].map do |item|
                        item.each do |k, v|
                            case k
                            when "currency"
                                item[k] = "ngn"
                            when "currency_symbol"
                                item[k] = "₦"
                            end
                        end
                    end
                   end
                else
                    case k
                    when "balance"
                        if @current_user.profiles.first.profile_type == "business"
                            response[k] = amount
                        else
                            response[k] = nil
                        end
                    when "currency"
                        response[k] = "ngn"
                    when "currency_symbol"
                        response[k] = "₦"
                    end
                end
            end
        end
    end

    def get_profile
        @current_user.profiles.first
    end
end