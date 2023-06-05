module Overrides
    class TokenValidationsController < DeviseTokenAuth::TokenValidationsController 
      # skip_before_action :verify_authenticity_token
      include Response
  
  
      protected

        def render_validate_token_success
            json_response({
                status: 200,
                data: resource_data(resource_json: @resource.token_validation_response),
                message: 'success',
                errMessage: nil
            })
        end
  
        def render_validate_token_error
            json_response({
                status: 401,
                data: nil,
                message: nil,
                errMessage: I18n.t('devise_token_auth.token_validations.invalid')
            }, :unauthorized)
        end
    end
end