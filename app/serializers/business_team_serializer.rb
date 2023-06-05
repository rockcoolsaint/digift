class BusinessTeamSerializer < ActiveModel::Serializer
  attributes :id, :team_name


  # has_many :business_team_members

  # def membership
  #   members = []
  #   BusinessTeamMember.find_each do |member|
  #     members << member if member.business_team_id == object.id
  #   end 
  #   members
  # end
end
