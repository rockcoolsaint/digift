class BusinessTeamMember < ApplicationRecord
  belongs_to :profile
  belongs_to :business_team

  enum role: {
    admin: 0,
    member: 1
  }
end
