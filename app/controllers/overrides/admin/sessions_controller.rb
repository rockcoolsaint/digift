module Overrides
  module Admin
    class SessionsController < DeviseTokenAuth::SessionsController
      # skip_before_action :verify_authenticity_token
      include Response
      def create
        # Check
        field = (resource_params.keys.map(&:to_sym) & resource_class.authentication_keys).first
  
        @resource = nil
        if field
          q_value = get_case_insensitive_field_from_resource_params(field)
  
          @resource = find_resource(field, q_value)
        end
  
        if @resource && valid_params?(field, q_value) && (!@resource.respond_to?(:active_for_authentication?) || @resource.active_for_authentication?)
          valid_password = @resource.valid_password?(resource_params[:password])
          if (@resource.respond_to?(:valid_for_authentication?) && !@resource.valid_for_authentication? { valid_password }) || !valid_password
            return render_create_error_bad_credentials
          end
          # @token = @resource.create_token
          # @resource.save

          @token = @resource.create_token
          @resource.save!
          update_auth_header
  
          sign_in(:user, @resource, store: false, bypass: false)
  
          yield @resource if block_given?
  
          render_create_success
        elsif @resource && !(!@resource.respond_to?(:active_for_authentication?) || @resource.active_for_authentication?)
          if @resource.respond_to?(:locked_at) && @resource.locked_at
            render_create_error_account_locked
          else
            render_create_error_not_confirmed
          end
        else
          render_create_error_bad_credentials
        end
      end
  

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
end