class AdminInvite < ApplicationRecord
  belongs_to :admin

  enum role: {
    admin: 0,
    finance: 1
  }
end
