module Overrides
  class PasswordsController < DeviseTokenAuth::PasswordsController
    include Response


    protected
		def render_update_error_unauthorized
			json_response({
					status: 401,
					data: nil,
					message: 'error',
					errMessage: 'Unauthorized'
				}, :unauthorized)
		end
	
		def render_update_error_password_not_required
			json_response({
					status: 422,
					data: nil,
					message: 'error',
					errMessage: I18n.t('devise_token_auth.passwords.password_not_required', provider: @resource.provider.humanize)
				}, :unprocessable_entity)
		end
	
		def render_update_error_missing_password
			json_response({
					status: 422,
					data: nil,
					message: 'error',
					errMessage: I18n.t('devise_token_auth.passwords.missing_passwords')
				}, :unprocessable_entity)
		end
	
		def render_update_success
			json_response({
					status: 200,
					data: resource_data,
					message: I18n.t('devise_token_auth.passwords.successfully_updated'),
					errMessage: 'error'
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
  end 
	
end 