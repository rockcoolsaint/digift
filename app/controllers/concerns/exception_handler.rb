module ExceptionHandler
  # provides the more graceful `included` method
  extend ActiveSupport::Concern

  # Define custom error subclasses - rescue catches `StandardErrors`
  class InvalidProfileType < StandardError; end
  class InvalidAPIKey < StandardError; end
  class DataType < StandardError; end
  class InvalidToken < StandardError; end
  class RestClientExceptionsOpenTimeout < StandardError; end
  class InvalidPhoneNumber < StandardError; end
  class RegularError < StandardError; end
  class UnknownError < StandardError; end
  # class Record < StandardError;

  class RestClientExceptionWithResponse < StandardError; end


  included do
    rescue_from ExceptionHandler::InvalidProfileType, with: :four_twenty_two

    rescue_from ExceptionHandler::InvalidAPIKey, with: :four_zero_three

    rescue_from ExceptionHandler::DataType, with: :four_zero_three

    rescue_from ExceptionHandler::InvalidToken, with: :four_twenty_two

    rescue_from ExceptionHandler::InvalidPhoneNumber, with: :four_twenty_two

    rescue_from ExceptionHandler::RestClientExceptionsOpenTimeout,  with: :four_zero_eight

    rescue_from ExceptionHandler::RestClientExceptionWithResponse do |e|
      json_response({ status: e.http_code || 500, data: nil, message: nil, errMessage: e.message || e  }, e.http_code || :internal_server_error)
    end

    rescue_from ExceptionHandler::RegularError do |e|
      json_response({ status: 422, data: nil, message: 'Error', errMessage: e.message || e  }, :unprocessable_entity)
    end

    rescue_from ExceptionHandler::UnknownError do |e|
      json_response({ status: 500 , data: nil, message: 'Error', errMessage: e.message || e  }, :internal_server_error)
    end
  end


  private

  def four_zero_three(e)
    json_response({ status: 403, data: nil, message: nil, errMessage: e.message || e }, :forbidden)
  end


  def four_zero_eight(e)
    json_response({ status: 408, data: nil, message: nil, errMessage: e.message || e }, :request_timeout)
  end

  # JSON response with message; Status code 422 - unprocessable entity
  def four_twenty_two(e)
    json_response({ status: 422, data: nil, message: nil, errMessage: e.message || e  }, :unprocessable_entity)
  end

 
end