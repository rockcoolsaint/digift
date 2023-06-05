class CorporateTeamMemberRegistrationService
  def initialize(params)
    @user = params[:user]
    @email = params[:email]
    @first_name = params[:first_name]
    @last_name = params[:last_name]
    @phone_number = params[:phone_number]
    @profile_type = params[:profile_type]
    @invite_code = params[:invite_code]
  end

  # Service entry point
  def call
    ActiveRecord::Base.transaction do
      existing_profile = Profile.find_by(user_id: @user.id)
      invite = TeamInvite.where(code: @invite_code, is_verified: true)
      raise(ExceptionHandler::InvalidProfileType, "your invite token is no longer valid, please request a invite") unless invite.exists?
      invite = TeamInvite.find_by(code: @invite_code)
      business_team = BusinessTeam.find(invite.business_team_id)

      # cannot have more than 2 profiles
      # if profile exists for the current user_id && the profile hash length is <= 2
      if !existing_profile || existing_profile.profile_type != @profile_type
        profile = Profile.create!(
        first_name: @first_name,
        last_name: @last_name,
        phone_number: @phone_number,
        profile_type: @profile_type,
        user_id: @user.id )
      elsif existing_profile && existing_profile.profile_type === @profile_type # prevent from creating multiple profiles of the same type
        raise(ExceptionHandler::InvalidProfileType, "You probably already have a #{@profile_type} profile type")
      end

      # create default business team admin memeber
      BusinessTeamMember.create!(
        business_team: business_team,
        role: invite.role,
        profile: profile
      )
      invite.destroy
    end
  end

  private

end