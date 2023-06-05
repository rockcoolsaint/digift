class TeamInvite < ApplicationRecord
  belongs_to :business
  belongs_to :business_team


  enum role: {
    admin: 0,
    member: 1
  }
end
