module Overrides
  class SessionsController < DeviseTokenAuth::SessionsController
    # skip_before_action :verify_authenticity_token
    include Response


    protected

    def render_new_error
      json_response({
        status: 405,
        data: nil,
        message: nil,
        errMessage: I18n.t('devise_token_auth.sessions.not_supported')
      }, :method_not_allowed)
    end

    def render_create_success
      json_response({
        status: 200,
        data: resource_data(resource_json: @resource.token_validation_response),
        message: "Welcome back #{resource_data['email']}",
        errMessage: nil
      })
    end

    def render_create_error_account_locked
      json_response({
        status: 401,
        data:nil,
        message: nil,
        errMessage: I18n.t('devise.mailer.unlock_instructions.account_lock_msg')
      }, :unauthorized)
    end

    def render_create_error_bad_credentials
      json_response({
        status: 401,
        data:nil,
        message: nil,
        errMessage: I18n.t('devise_token_auth.sessions.bad_credentials')
      }, :unauthorized)
    end


    def render_create_error_not_confirmed
      json_response({
        status: 401,
        data:nil,
        message: nil,
        errMessage: I18n.t('devise_token_auth.sessions.not_confirmed', email: @resource.email)
      }, :unauthorized)
    end

    def render_destroy_error
      json_response({
        status: 404,
        data:nil,
        message: nil,
        errMessage: I18n.t('devise_token_auth.sessions.user_not_found')
      }, :not_found)
    end

    def render_destroy_success
      json_response({
        status: 200,
        data:nil,
        message: "success",
        errMessage: nil
      })
    end
  end

end