class UserSerializer < ActiveModel::Serializer
  attributes :id, :uid, :provider, :email

  # has_many :profiles
end
