class Profile < ApplicationRecord
  belongs_to :user
  has_one :business
  has_many :wallets
  has_many :business_teams
  has_many :business_team_members
  has_many :transaction_logs

  validates_presence_of :phone_number, :profile_type
  validates :phone_number, phone: { possible: true, allow_blank: false, types: [:voip, :mobile], countries: [:us, :ng] }, on: :create
  validates :phone_number, phone: { possible: true, allow_blank: false, types: [:voip, :mobile], countries: [:us, :ng] }, on: :update

  def get_id
    where(profile_type: "business")
  end

  # def self.get_business
  #   where()
  # end
end
