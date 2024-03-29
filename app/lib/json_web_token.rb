class JsonWebToken
    # secret to encode and decode token
    HMAC_SECRET = Rails.application.secret_key_base
  
    def self.encode(payload, exp = 1.hours.from_now)
      # set expiry to 24 hours from creation time
      payload[:exp] = exp.to_i
      # sign token with application secret
      JWT.encode(payload, HMAC_SECRET)
    end
  
    def self.decode(token)
      # get payload; first index in decoded Array
      body = JWT.decode(token, HMAC_SECRET)[0]
      HashWithIndifferentAccess.new body
      # rescue from all decode errors
    rescue JWT::ExpiredSignature
      raise ExceptionHandler::InvalidToken, "your token is expired, please request a new token"
    rescue JWT::DecodeError => e
      # raise custom error to be handled by custom handler
      raise ExceptionHandler::InvalidToken, e.message
    end

    def self.verify(token)
      body = JWT.verify(token, HMAC_SECRET)
    end
  end