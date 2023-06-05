class ValidateNewRetailTransaction
    def initialize(current_user:, amount:, transaction_log:)
        @current_user = current_user,
        @amount = amount.try(:to_f)
        @transaction_log = transaction_log
        @errors = []
    end

    def execute!
      validate_transaction_amount!
      @errors
    end
    
    private
    
    def validate_transaction_amount!
      # if ENV["TEST_MODE"] != true
        begin

          @errors << "transaction reference not found" if @transaction_log.blank?

          if @transaction_log.is_discounted == true
            calc_transaction_amount = (@transaction_log.amount.try(:to_f) * (@transaction_log.discount_rate.try(:to_f))).ceil 
            calc_amount = (@amount * (@transaction_log.discount_rate.try(:to_f))).ceil
            if calc_transaction_amount != calc_amount
              @errors << "Amount don't match up for discounted gift card purchase"
            end
          else
            if @amount.try(:ceil) != @transaction_log.amount.try(:to_f)
              @errors << "Amount don't match up for gift card purchase"
            end
          end



        rescue => e
          raise(ExceptionHandler::RegularError, e)
        end
      # end
    end
    
end