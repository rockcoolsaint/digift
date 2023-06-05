class Api::V1::InviteActionsController < ApplicationController
    before_action :authenticate_user!, only: [:send_team_invite_email, :remove_business_team_member, :get_invite_roles]
    before_action :validate_business_user!, only: [:send_team_invite_email, :remove_business_team_member]
    before_action :set_current_business, only: [:send_team_invite_email, :remove_business_team_member]
    before_action :validate_business_user_is_admin!, only:[:send_team_invite_email, :remove_business_team_member]


    def send_team_invite_email

        begin
            invite = TeamInvite.where("created_at >= ? AND email = ? AND is_verified = ?", (Time.current - 604800), send_invite_params[:email], false)

            if invite.exists?
                invite = TeamInvite.find_by(email: send_invite_params[:email])
                if ENV['RAILS_ENV'] != 'production'
                    TeamMailer.invite_to_business_team(send_invite_params[:email], @current_business.business_name, @current_business.business_name, invite.code).deliver
                else
                    TeamMailer.invite_to_business_team(send_invite_params[:email], @current_business.business_name, @current_business.business_name, invite.code).deliver_later
                end
            else
                profile = User.where(email: send_invite_params[:email])
                raise ExceptionHandler::RegularError, "This email is aleady used by user" if profile.exists?
                TeamInvite.where("created_at < ? AND email = ?", (Time.current - 604800), send_invite_params[:email]).destroy_all
                profile_id = @current_user.profiles.first.id
                reference = generate_ref_id
            
                TeamInvite.create!(code: reference, email: send_invite_params[:email], role: send_invite_params[:role], business_team_id: send_invite_params[:team_id], business: @current_business)
                if ENV['RAILS_ENV'] != 'production'
                    TeamMailer.invite_to_business_team(send_invite_params[:email], @current_business.business_name, @current_business.business_name, reference).deliver
                else
                    TeamMailer.invite_to_business_team(send_invite_params[:email], @current_business.business_name, @current_business.business_name, reference).deliver_later
                end

            end
        
            json_response({
                status: 200,
                data: nil,
                message: "invite sent",
                errMessage: nil
            })
        rescue Exception => e   
            raise ExceptionHandler::RegularError, e
        end
    end

    def verify_team_invite_email
        begin
        
            invite = TeamInvite.where("created_at >= ? AND code = ?", (Time.current - 604800), verify_invite_params[:invite_code])

            if invite.exists?
                invite = TeamInvite.find_by(code: verify_invite_params[:invite_code])
                business = Business.find(invite.business_id)
                invite.update(is_verified: true)
                json_response({
                    status: 200,
                    data: {
                        business: ActiveModelSerializers::SerializableResource.new(business, each_serializer: BusinessInviteSerializer)
                    },
                    message: "invite verified",
                    errMessage: nil
                })
              else
                raise ExceptionHandler::InvalidToken, "your invite token does not exist/has already been confirm! please request a new invite from business admin"
              end
        rescue Exception => e
            raise ExceptionHandler::RegularError, e
        end
    end

    def get_invite_roles
        json_response({
            status: 200,
            data: {
                roles: [
                    {
                        title: "Admin",
                        value: "admin",
                        is_active: true
                    },
					{
                        title: "Member",
                        value: "member",
                        is_active: true
				    }
                ]
            },
            message: 'these are the available roles',
            errMessage: nil
        })
    end

    def remove_business_team_member
        begin
            member = BusinessTeamMember.where(id: remove_business_team_member_params[:memberId])
            raise ExceptionHandler::InvalidProfileType, "action prohibited, couldn't find any team member with this id" unless member.exists?
            member = BusinessTeamMember.find(remove_business_team_member_params[:memberId])
            raise ExceptionHandler::InvalidProfileType, "you can't remove yourself from a team" if member.profile_id == @current_user.profiles.first.id
            profile = Profile.find(member.profile_id)
            user = User.find(profile.user_id)

            if ENV['RAILS_ENV'] != 'production'
                TeamMailer.remove_from_business_team(user.email, @current_business.business_name, profile.first_name).deliver
            else
                TeamMailer.remove_from_business_team(user.email, @current_business.business_name, profile.first_name).deliver_later
            end

            member.destroy
            profile.destroy
            user.destroy
            
            json_response({
                status: 200,
                data: nil,
                message: "business team member removed from team",
                errMessage: nil
            })
        rescue => e
            raise ExceptionHandler::RegularError, e 
        end
    end

    private

    def send_invite_params
        params.require(:data).permit(:email, :role, :team_id)
    end


    def verify_invite_params
        params.permit(:invite_code)
    end

    def remove_business_team_member_params
		params.permit(:memberId)
	end

    

end