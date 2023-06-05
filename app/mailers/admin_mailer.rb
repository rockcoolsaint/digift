class AdminMailer < ApplicationMailer
  def admin_invite(to_address, invited_by, reference)
      @to_address = to_address
      @reference = reference
      @invited_by = invited_by
      mail(to: @to_address, subject: "Invite to Join Digiftng admin")
  end
end
