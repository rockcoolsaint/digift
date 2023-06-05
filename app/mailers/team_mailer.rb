class TeamMailer < ApplicationMailer
    def invite_to_business_team(to_address, invited_by, business_name, reference, invitee='')
        @to_address = to_address
        @reference = reference
        @invited_by = invited_by
        @business_name = business_name
        @invitee = invitee
        mail(to: @to_address, 
            subject: "Invite to Join Business Team on Digiftng",
            template_path: 'team_mailer',
            template_name: 'invite_to_business_team')
    end

    def remove_from_business_team(to_address, business_name, member='')
        @to_address = to_address
        @business_name = business_name
        @member = member 
        mail(to: @to_address, 
            subject: "Removal from Business Team on Digiftng",
            template_path: 'team_mailer',
            template_name: 'remove_from_business_team')
    end
end
