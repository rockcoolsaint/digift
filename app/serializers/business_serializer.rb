class BusinessSerializer < ActiveModel::Serializer
  attributes :id, :business_name, :industry, :country_of_incorporation, :staff_strength, :registration_status, :role_at_business, :website, :is_live, :api_key, :test_key

  # belongs_to :profile
end
