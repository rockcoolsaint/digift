class Vendor < ApplicationRecord
    belongs_to :profile
    # has_many :business_teams
    has_many :ledgers
  
    validates_presence_of :business_name, :industry, :country_of_incorporation, :registration_status
  
    scope :current_vendor_by_liveKey, -> (apikey) { 
      raise ExceptionHandler::InvalidToken, "invalid apikey" unless Vendor.where("live_key = ?", apikey).exists?
      Vendor.where("live_key = ?", apikey).first.profile.user 
    }
    scope :current_vendor_by_testKey, -> (testkey) { 
      raise ExceptionHandler::InvalidToken, "invalid apikey" unless Vendor.where("test_key = ?", testkey).exists?
      Vendor.where("test_key = ?", testkey).first.profile.user 
    }
end
