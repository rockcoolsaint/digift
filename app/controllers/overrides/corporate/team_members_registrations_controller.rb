module Overrides
  module Corporate
    class TeamMembersRegistrationsController < DeviseTokenAuth::RegistrationsController
      include Response

      def create
        ActiveRecord::Base.transaction do
          super do |resource|
            begin
              CorporateTeamMemberRegistrationService.new({
                user: resource,
                email: params[:email],
                first_name: params[:first_name],
                last_name: params[:last_name],
                phone_number: params[:phone_number],
                profile_type: "business",
                invite_code: params[:invite_code]
              }).call
          rescue => e
            raise ExceptionHandler::RegularError, e
          end
          end
        end
      end

      protected

      def render_create_success
        json_response({
          status: 200,
          data: resource_data,
          message: "Welcome #{resource_data['email']}, Please check your email to confirm your registration",
          errMessage: nil
        })
      end

      def render_create_error
        json_response({
          status: 422,
          data: nil,
          message: 'error',
          errMessage: resource_errors[:full_messages][0]
        }, :unprocessable_entity)
      end


      def render_create_error_missing_confirm_success_url

        json_response({
          status: 422,
          data: resource_data,
          message:  I18n.t('devise_token_auth.registrations.missing_confirm_success_url'),
          errMessage: resource_errors[:full_messages][0]
        }, :unprocessable_entity)
    
      end

      def render_create_error_redirect_url_not_allowed

        json_response({
          status: 422,
          data: resource_data,
          message:  nil,
          errMessage: I18n.t('devise_token_auth.registrations.redirect_url_not_allowed', redirect_url: @redirect_url)
        }, :unprocessable_entity)
    
      end


      def render_update_success
        json_response({
          status: 200,
          data: resource_data,
          message:  'Success',
          errMessage: nil
        })
      end

      def render_update_error

        json_response({
          status: 422,
          data: resource_data,
          message: 'error',
          errMessage: resource_errors[:full_messages][0]
        }, :unprocessable_entity)
      end

      def render_update_error_user_not_found

        json_response({
          status: 404,
          data: nil,
          message: 'error',
          errMessage: I18n.t('devise_token_auth.registrations.user_not_found')
        }, :not_found)

      end

      def render_destroy_success

        json_response({
          status: 200,
          data: nil,
          message:  I18n.t('devise_token_auth.registrations.account_with_uid_destroyed', uid: @resource.uid),
          errMessage: nil
        })

      end

      def render_destroy_error
        json_response({
          status: 404,
          data: nil,
          message: 'error',
          errMessage: I18n.t('devise_token_auth.registrations.account_to_destroy_not_found')
        }, :not_found)

      end
    end
  end 
end