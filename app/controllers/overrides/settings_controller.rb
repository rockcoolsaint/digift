module Overrides
  class SettingsController < DeviseTokenAuth::RegistrationsController
    def update
      ActiveRecord::Base.transaction do
        super do |resource|

          resource.update!(user_params)
          @message = "#{resource_data['email']} was successfully updated"


          if User.exists?(email: user_params[:email]) != true
            @message = "#{resource_data['email']} update successful, to confirm new email, please check inbox"
          end


          profile = resource.profiles.first

          profile.update!(profile_params[:profile])


          if profile.profile_type == "business"
            business = profile.business
            business.update!(business_params[:business]) if business_params[:business] && !business_params[:business].empty?
          end
        end
      end
    end

    protected
    def render_update_success
      json_response({
        status: 200,
        data: resource_data,
        message: @message,
        errMessage: nil
      })
    end

    private 
    def user_params
      params.permit(:email)
    end

    def profile_params
      params.require(:data).permit(profile: [:first_name, :last_name, :phone_number, :image, :bvn])
    end

    def business_params
      params.require(:data).permit(business: [:business_name, :industry, :country_of_incorporation, :staff_strength, :registration_status, :role_at_business, :website])
    end
  end
end