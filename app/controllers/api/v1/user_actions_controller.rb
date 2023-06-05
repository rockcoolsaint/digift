class Api::V1::UserActionsController < ApplicationController
  # skip_before_action :verify_authenticity_token
  before_action :authenticate_user!
  before_action :validate_business_user!, only: [:go_live]
  before_action :set_current_business, except: [:me]
  
  # before_action :set_user

  def me

    begin
      if @current_user.profiles.first.profile_type == 'business'
        my_membership = BusinessTeamMember.find_by(profile_id: @current_user.profiles.first.id)
        my_team = BusinessTeam.find_by(id: my_membership.business_team_id)
        my_business = Business.find_by(id: my_team.business_id)
        json_response({
          status: 200,
          data: {
            user: ActiveModelSerializers::SerializableResource.new(@current_user, each_serializer: UserSerializer),
            profile: ActiveModelSerializers::SerializableResource.new(@current_user.profiles.first, each_serializer: ProfileSerializer),
            business: ActiveModelSerializers::SerializableResource.new(my_business, each_serializer: BusinessSerializer),
            team: ActiveModelSerializers::SerializableResource.new(my_team, each_serializer: BusinessTeamSerializer),
            membership: ActiveModelSerializers::SerializableResource.new(my_membership, each_serializer: BusinessTeamMemberSerializer),
            wallet: ActiveModelSerializers::SerializableResource.new(my_business.wallets, each_serializer: WalletSerializer)
          },
          message: "Found User #{@current_user[:email]}",
          errMessage: nil
        })
      else
        json_response({
          status: 200,
          data: {
            user: ActiveModelSerializers::SerializableResource.new(@current_user, each_serializer: UserSerializer),
            profile: ActiveModelSerializers::SerializableResource.new(@current_user.profiles.first, each_serializer: ProfileSerializer),
            business: nil,
            team: nil,
            membership: nil,
            wallet:nil
          },
          message: "Found User #{@current_user[:email]}",
          errMessage: nil
        })
      end
     
    rescue Exception => e
      raise ExceptionHandler::RegularError, e
    end
   
  end

  def my_wallet

    begin
      json_response({
        status: 200,
        data: {
          wallet: ActiveModelSerializers::SerializableResource.new(@current_business.wallets, each_serializer: WalletSerializer)
        },
        message: "Found User #{@current_user[:email]}'s Wallet",
        errMessage: nil
      })
    rescue Exception => e
      raise ExceptionHandler::RegularError, e
    end
   
  end

  def go_live
      email =  @current_user.email
      profile_id = @current_user.profiles.first.id
      profile = Profile.find_by!(id: profile_id)
      profile.update(test_mode: go_live_params[:test_mode])
      message = !profile.test_mode ? "#{email} is currently in live mode" : "#{email} is currently in test mode"

      json_response({
        status: 200,
        data: profile,
        message: message,
        errMessage: nil
      })
  end

  def fetch_team_members

    begin
      members = []
      my_membership = BusinessTeamMember.find_by(profile_id: @current_user.profiles.first.id)
      my_team = BusinessTeam.find_by(id: my_membership.business_team_id)
      # my_business = Business.find_by(id: my_team.business_id)
      BusinessTeamMember.find_each do |member|
        members << member if member.business_team_id == my_team.id
      end 
      json_response({
        status: 200,
        data: {
          team_members: ActiveModelSerializers::SerializableResource.new(members, each_serializer: BusinessTeamMemberSerializer) 
        },
        message: "team members on '#{my_team.team_name}' for Business '#{@current_business.business_name}'",
        errMessage: nil
      })
    rescue Exception => e
      raise ExceptionHandler::RegularError, e
    end
  end

  def fetch_keys
    
  end

  def patch_keys
    
  end
  private
 

  def go_live_params
    params.require(:data).permit(
      :test_mode
    )
  end


  # def set_user
  #   @user = User.find(params[:id])
  # end
end
