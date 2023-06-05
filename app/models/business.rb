class Business < ApplicationRecord
  belongs_to :profile
  has_many :business_teams
  has_many :wallets

  validates_presence_of :business_name, :industry, :country_of_incorporation, :registration_status, :role_at_business

  scope :current_business_by_apiKey, -> (apikey) { 
    raise ExceptionHandler::InvalidToken, "invalid apikey" unless Business.where("api_key = ?", apikey).exists?
    Business.where("api_key = ?", apikey).first.profile.user 
  }
  scope :current_business_by_testKey, -> (testkey) { 
    raise ExceptionHandler::InvalidToken, "invalid apikey" unless Business.where("test_key = ?", testkey).exists?
    Business.where("test_key = ?", testkey).first.profile.user 
  }
end
