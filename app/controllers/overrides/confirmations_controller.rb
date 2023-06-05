module Overrides
  class ConfirmationsController < DeviseTokenAuth::ConfirmationsController
    # skip_before_action :verify_authenticity_token

    # def show
    #   @resource = resource_class.confirm_by_token(resource_params[:confirmation_token])

    #   if @resource.errors.empty?
    #     yield @resource if block_given?

    #     redirect_header_options = { account_confirmation_success: true }

    #     if signed_in?(resource_name)
    #       token = signed_in_resource.create_token
    #       signed_in_resource.save!

    #       redirect_headers = build_redirect_headers(token.token,
    #                                                 token.client,
    #                                                 redirect_header_options)

    #       redirect_to_link = signed_in_resource.build_auth_url(redirect_url, redirect_headers)
    #     else
    #       token = @resource.create_token
    #       sign_in(:user, resource, store: false, bypass: false)
    #       new_auth_header = @resource.build_auth_header(token.token, token.client)
    #       response.headers.merge!(new_auth_header)
    #       redirect_to_link = DeviseTokenAuth::Url.generate(redirect_url, redirect_header_options)
    #     end

    #     redirect_to(redirect_to_link)
    #   else
    #     raise ActionController::RoutingError, 'Not Found'
    #   end

    # end


    def show
      @resource = resource_class.confirm_by_token(resource_params[:confirmation_token])

      if @resource.errors.empty?
        yield @resource if block_given?

        redirect_header_options = { account_confirmation_success: true }

        if signed_in?(resource_name)
          token = signed_in_resource.create_token
          signed_in_resource.save!

          redirect_headers = build_redirect_headers(token.token,
                                                    token.client,
                                                    redirect_header_options)

          redirect_to_link = signed_in_resource.build_auth_url(redirect_url, redirect_headers)
        else
          redirect_to_link = DeviseTokenAuth::Url.generate(redirect_url, redirect_header_options)
       end

        redirect_to(redirect_to_link)
      else
        # raise ActionController::RoutingError, 'Not Found'
        redirect_url = "#{ENV["WEB_APP_URL"]}?failed_confirmation=true"
        redirect_to(redirect_url) 
      end
    end


    protected

    def render_create_error_missing_email
      json_response({
        status: 401,
        data: nil,
        message: "Error",
        errMessage: I18n.t('devise_token_auth.confirmations.missing_email')
      }, :unauthorized)
    end

    def render_create_success

      json_response({
        status: 200,
        data: nil,
        message: I18n.t('devise_token_auth.confirmations.sended', email: @email),
        errMessage: nil
      })

    end

    def render_not_found_error
      json_response({
        status: 404,
        data: nil,
        message: "Error",
        errMessage: I18n.t('devise_token_auth.confirmations.user_not_found', email: @email)
      }, :not_found)
  
    end

    private

    def resource_params
      params.permit(:email, :confirmation_token, :config_name)
    end

    # give redirect value from params priority or fall back to default value if provided
    def redirect_url
      params.fetch(
        :redirect_url,
        DeviseTokenAuth.default_confirm_success_url
      )
    end
  end
end