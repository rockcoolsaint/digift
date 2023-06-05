class BusinessTeamMemberSerializer < ActiveModel::Serializer
  attributes :id, :role

  belongs_to :business_team
  has_one :profile

end
