class ProfileSerializer < ActiveModel::Serializer
  attributes :id, :first_name, :last_name, :phone_number, :profile_type, :image, :test_mode, :bvn, :is_verified

  belongs_to :user
end
