class BusinessTeam < ApplicationRecord
  belongs_to :profile
  belongs_to :business

  has_many :business_team_members
end
