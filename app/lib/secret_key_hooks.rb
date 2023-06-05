module SecretKeyHooks
    def business_secret_key_prefix
       prefix = ( nil|| ENV["BUSINESS_SECRET_KEY_PREFIX"] || "DG_BUS_SK")
       {
         :live => "#{prefix}_LIVE",
         :test => "#{prefix}_TEST"
       }
      end
      def vendor_secret_key_prefix
        prefix = (nil|| ENV["VENDOR_SECRET_KEY_PREFIX"] || "DG_VEN_SK")
        {
          :live => "#{prefix}_LIVE",
          :test => "#{prefix}_TEST"
        }
      end

      def generate_test_key
        {
          :vendor => "#{vendor_secret_key_prefix[:test]}_#{SecureRandom.hex(16)}",
          :business => "#{business_secret_key_prefix[:test]}_#{SecureRandom.hex(16)}"
        }
      end
  
      def generate_live_key
        {
          :vendor => "#{vendor_secret_key_prefix[:live]}_#{SecureRandom.hex(16)}",
          :business => "#{business_secret_key_prefix[:live]}_#{SecureRandom.hex(16)}"
        }
      end
  end