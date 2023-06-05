class PerformVendorLocalTransaction
    # include Response

    # def initialize(current_user:, transaction_type:, ledger:, data:, total_amount:, gift_card_name:"", gift_card_logo:"", gift_card_min_range:"", gift_card_max_range:"", response_hash: )
    #     @current_user = current_user
    #     @transaction_type = transaction_type
    #     @ledger = ledger
    #     @data = data
    #     @total_amount = total_amount
    #     @gift_card_name = gift_card_name
    #     @gift_card_logo = gift_card_logo
    #     @gift_card_min_range = gift_card_min_range
    #     @gift_card_max_range = gift_card_max_range
    #     @response_hash = response_hash

        def initialize(params)
            # def initialize(current_user:, transaction_type:, ledger:, data:, total_amount:, gift_card_name:"", gift_card_logo:"", gift_card_min_range:"", gift_card_max_range:"")
                @current_user = params[:current_user]
                @transaction_type = params[:transaction_type]
                @ledger = params[:ledger]
                @data = params[:data]
                @total_amount = params[:total_amount]
                @gift_card_name = params[:gift_card_name] || ""
                @gift_card_logo = params[:gift_card_logo] || ""
                @gift_card_min_range = params[:gift_card_min_range] || ""
                @gift_card_max_range = params[:gift_card_max_range] || ""
                @response_hash = params[:response_hash]
    end

    def execute!
        card_response = []
        card = @data[:card]
        res = Concurrent::Future.execute do
            # some parallel work
            ActiveRecord::Base.transaction do

                credit = @ledger.credit.try(:to_d)
                debit = @ledger.debit.try(:to_d)
                if @ledger.credit.try(:to_d) > 0 && @ledger.credit - @total_amount.try(:to_d) > 0
                  credit = @ledger.credit.try(:to_d) - @total_amount.try(:to_d) 
                else
                  debit = @ledger.debit.try(:to_d) + @total_amount.try(:to_d)
                end
                balance = credit - debit
                @ledger.update!(balance: balance, credit: credit, debit: debit)
                
                @ledger_history = create_ledger_history(@ledger, @transaction_type, card[:dest], card[:amount], 'gift_card')

                @transaction_log = create_transaction_log(@ledger, @ledger_history, @transaction_type, 'pending', card[:code], card[:order_id])


                # dest =  ENV['MAIL_FROM'] || @data[:dest]

                # if card[:code] == "1334"
                #  dest = @data[:dest]  
                # end


                # payload ={
                #     "action": "#{@data[:action]}",
                #     "apikey": "#{ENV['CARD_VENDOR_API_KEY'] || ENV['API_KEY']}",
                #     "sender": "#{@data[:sender] || @current_user.profiles.first.vendor.business_name || 'Digiftng'}",
                #     "from": "#{ENV['ADMIN_PHONE_NUMBER']|| @data[:from]}",
                #     "dest": "#{dest}",
                #     "code": "#{card[:code]}",
                #     "amount": card[:amount],
                #     "postal": "#{@data[:postal] || ENV['DIGIFTNG_POSTAL'] }",
                #     "msg": "#{@data[:msg]}",
                #     "reference": "#{transaction_log.reference_id}",
                #     "handle_delivery": true
                # }

                payload = {
                    "SendEmail": false,
                    "DeliveryDate": "#{DateTime.now()}",
                    "OrderItemRequests": [{
                        "MerchantId": card[:code][4..].to_i || card[:card_code][4..].to_i,
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
                    response = RestClient.post("#{ENV['SUREGIFTS_API_V1']}/JSONProcessBulkOrder",
                        payload.to_json,
                         {Authorization: "Basic " + Base64::encode64("#{ENV['SUREGIFTS_USERNAME']}:#{ENV['SUREGIFTS_PASSWORD']}"), content_type: :json, accept: :json}
                     )
                rescue RestClient::Exceptions::OpenTimeout => e
                    raise(ExceptionHandler::RestClientExceptionsOpenTimeout, e)

                rescue RestClient::ExceptionWithResponse => e
                    raise(ExceptionHandler::RestClientExceptionWithResponse, e)
                end

                response_data = JSON.parse(response.body)
                details = @transaction_log.details
                if(response_data["StatusCode"] == "00")
                    @transaction_log.update!(details: details.merge({data: response_data, payload: payload}), status: 'delivered', is_active: true, gift_card_name: @gift_card_name)
                    @order = create_order(@transaction_log, card[:order_id], card[:amount], card[:code], response_data)
                else
                    @transaction_log.update!(details: details.merge({data: response_data, payload: payload}), gift_card_name: @gift_card_name)
                    @transaction_log.failed!
                    @ledger_history.update_attribute(:status, false)
                end

                card_response << response_data
                response_data
            end

            sanitize_response(@response_hash, card_response, @ledger, )
        end

        res.value!
    end

    private

    def create_transaction_log(ledger, ledger_history, transaction_type, status, gift_card_code, unique_card_order_id)
        TransactionLog.create!(
            ledger_id: ledger.id,
            ledger_history_id: ledger_history.id,
            reference_id: unique_card_order_id || generate_ref_id,
            profile_id: @current_user.profiles.first.id,
            gift_card_code: gift_card_code,
            log_type: transaction_type,
            status: status,
            amount: @total_amount,
            is_active: false,
            gift_card_name: @gift_card_name || "",
            transaction_rate: Fx.get_rate,
            details: {}
        )
    end

    def create_ledger_history(ledger, transaction_type, dest, amount, category)
        available_balance = ledger.balance
        profile = get_profile
        @vendor = Vendor.find_by!(profile: @current_user.profiles.first)
        LedgerHistory.create!(
            vendor: @vendor,
            ledger: ledger,
            profile_id: profile.id,
            sender_details: profile,
            preference: '',
            details: {},
            category: category,
            amount: amount,
            balance: available_balance,
            actual_amount: @total_amount,
            description: '',
            reference_code: '',
            status: true,
            is_active: true
        )
    end

    def create_order(transaction_log, unique_card_order_id, amount, gift_card_code, response)
        profile = get_profile
        Order.create!(
            profile: profile,
            transaction_log: transaction_log,
            card_order_id: unique_card_order_id || generate_ref_id,
            total_amount: @total_amount,
            amount: amount,
            quantity: 1,
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

    def sanitize_response(card_response, response_data, ledger)
        card_response.map do |response|
            response.each do |k, v|
                if response[k].respond_to? :to_ary
                    response[k].map do |item|
                        item.each do |k, v|
                            case k
                            when "currency"
                                item[k] = "NGN"
                            when "code"
                                item[k] = response_data[0].with_indifferent_access[:Data][0].with_indifferent_access[:Voucher][0]
                            when "currency_symbol"
                                item[k] = "₦"
                            when "SKU"
                                item[k] = nil
                            when "amount"
                                item[k] = @data[:card][:amount]
                            when "barcode_format"
                                item[k] = ""
                            when "buttontext"
                                item[k] = ""
                            when "calltoaction"
                                item[k] = ""
                            when "caption"
                                item[k] = @gift_card_name
                            when "datetimestamp"
                                data = response_data[0].with_indifferent_access[:Data]
                                item[k] = data[0].with_indifferent_access[:VoucherExpiryDate]
                            when "domain"
                                item[k] = ENV['BASE_DOMAIN'] || response[k]
                            when "egc"
                                item[k] = nil
                            when "egc_key"
                                item[k] = nil
                            when "egc_text"
                                item[k] = nil 
                            when "expiry_date"
                                data = response_data[0].with_indifferent_access[:Data]
                                item[k] = data[0].with_indifferent_access[:VoucherExpiryDate]
                            when "fees"
                                item[k] = 0.0
                            when "id"
                                item[k] = @order.id
                            when "iso"
                                item[k] = "ng"
                            when "logo"
                                item[k] = @gift_card_logo
                            when "min_range"
                                item[k] = @gift_card_min_range
                            when "max_range"
                                item[k] = @gift_card_max_range
                            when "msg"
                                item[k] = @data[:msg]
                            when "reference"
                                item[k] = nil
                            when "sessionid"
                                item[k] = nil
                            when "sender"
                                item[k] = "#{@data[:sender] || @current_user.profiles.first.vendor.business_name || 'Digiftng'}"
                            when "value"
                                item[k] = @data[:card][:amount]
                                
                            end
                        end
                    end
                else
                    case k
                    when "balance"
                        if @current_user.profiles.first.profile_type == "vendor"
                            response[k] = ledger.balance.try(:to_d)
                        else
                            response[k] = nil
                        end
                    when "currency"
                        response[k] = "ngn"
                    when "currency_symbol"
                        response[k] = "₦"
                    when "amount"
                        response[k] = @total_amount
                    when "MID"
                        response[k] = @ledger.try(:vendor_id)
                    when "domain"
                        response[k] = ENV['BASE_DOMAIN'] || response[k]
                    when "id"
                        response[k] = @transaction_log.id
                    when "iso"
                        response[k] = "ng"
                    when "msg"
                        response[k] = @data[:msg]
                    when "param"
                        response[k] = "#{@data[:sender] || @vendor.business_name || 'Digiftng'}"
                    when "prompt"
                        response[k] = @gift_card_name
                    when "reference"
                        response[k] = @transaction_log.id
                    when "ribbon_status"
                        response[k] = false
                    when "text"
                        response[k] = 'ng'
                    when "timestamp"
                        response[k] = Time.now
                    when "value"
                        response[k] = @data[:card][:amount]
                    when "token"
                        response[k] = ""
                    end
                end
            end
        end
        # [response_data]
    end

    def get_profile
        @current_user.profiles.first
    end
end