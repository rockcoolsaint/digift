class HomeController < ApplicationController
  # skip_before_action :verify_authenticity_token
  skip_before_action :authorize_request, only: [:index]

  def index
    if params[:account_confirmation_success]
      redirect_to  ENV['WEB_APP_URL'] || "https://digiftng.com" if params[:account_confirmation_success]
    else
      render plain: 'Welcome to Digift Nigeria'
    end
  end
end
