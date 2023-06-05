class BusinessInviteSerializer < ActiveModel::Serializer
  attributes :id, :business_name, :industry, :website, :is_live
end
