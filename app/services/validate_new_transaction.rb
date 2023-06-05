class ValidateNewTransaction
    def initialize(current_user:, amount:, transaction_type:, wallet:, transaction_log:, ledger:nil)
        @current_user = current_user,
        @amount = amount.try(:to_f)
        @transaction_type = transaction_type
        @wallet = wallet
        @transaction_log = transaction_log
        @errors = []
        @ledger = ledger

    end

    def execute!
      
      if @transaction_type == "send" and @wallet.present?
        validate_existence_of_wallet!
        validate_send!
      end


      if @transaction_type == "send_vendor"
        if @ledger.present? && @ledger.is_active
          validate_send_vendor!
        else
          @errors << "no active ledger account associated with this request, please contact support for assistance"
        end
        # validate_send!
      end

      if @transaction_type == "airtime" and @transaction_log.present?
        validate_airtime!
      end

      if @transaction_type == "cabletv" and @transaction_log.present?
        validate_cabletv!
      end

      if @transaction_type == "electricbill" and @transaction_log.present?
        validate_electricbill!
      end

      if @transaction_type == "epin" and @transaction_log.present?
        validate_epin!
      end

      @errors
    end
    
    private

    def validate_send!
  
      if @wallet.available_balance - @amount < 0.00
        @errors << "Not enough funds in wallet"
      end

    end


    def validate_airtime!
      begin
        @errors << "transaction reference not found" if @transaction_log.blank?
        if @transaction_log.is_discounted == true
          calc_transaction_amount = (@transaction_log.amount.try(:to_f) * (@transaction_log.discount_rate.try(:to_f))).ceil
          calc_amount = (@amount * (@transaction_log.discount_rate.try(:to_f))).ceil
          if calc_transaction_amount != calc_amount
            @errors << "Amount don't match up for airtime purchase"
          end
        else
          if @amount != @transaction_log.amount.try(:to_f)
            @errors << "Amount don't match up for airtime purchase"
          end
        end
      rescue => e
        raise(ExceptionHandler::RegularError, e)
      end
    end


    def validate_cabletv!
      begin
        @errors << "transaction reference not found" if @transaction_log.blank?
        if @transaction_log.is_discounted == true
          calc_transaction_amount = (@transaction_log.amount.try(:to_f) * (@transaction_log.discount_rate.try(:to_f))).ceil
          calc_amount = (@amount * (@transaction_log.discount_rate.try(:to_f))).ceil
          if calc_transaction_amount != calc_amount
            @errors << "Amount don't match up for airtime purchase"
          end
        else
          if @amount != @transaction_log.amount.try(:to_f)
            @errors << "Amount don't match up for airtime purchase"
          end
        end
      rescue => e
        raise(ExceptionHandler::RegularError, e)
      end

    end


    def validate_electricbill!
      begin
        @errors << "transaction reference not found" if @transaction_log.blank?
        if @transaction_log.is_discounted == true
          calc_transaction_amount = (@transaction_log.amount.try(:to_f) * (@transaction_log.discount_rate.try(:to_f))).ceil
          calc_amount = (@amount * (@transaction_log.discount_rate.try(:to_f))).ceil
          if calc_transaction_amount != calc_amount
            @errors << "Amount don't match up for electric purchase"
          end
        else
          if @amount != @transaction_log.amount.try(:to_f)
            @errors << "Amount don't match up for electric purchase"
          end
        end
      rescue => e
        raise(ExceptionHandler::RegularError, e)
      end

    end

    def validate_epin!
      begin
        @errors << "transaction reference not found" if @transaction_log.blank?
        if @amount != @transaction_log.amount.try(:to_f)
            @errors << "Amount don't match up for epin service"
        end
      rescue => e
        raise(ExceptionHandler::RegularError, e)
      end

    end
    
    def validate_existence_of_wallet!

      if @wallet.blank?
        @errors << "Account not found"
      end

    end

    def validate_send_vendor!
      begin
        # @errors << "transaction reference not found" if @transaction_log.blank?
        # if @amount != @transaction_log.amount.try(:to_f)
        #     @errors << "Amount don't match up for epin service"
        # end
        if @ledger.use_credit
          if @ledger.credit - @amount <= 0.0
            @errors << "this transaction will exceed your current credit threshold"
          end
        end
        
      rescue => e
        raise(ExceptionHandler::RegularError, e)
      end
    end
    
  end