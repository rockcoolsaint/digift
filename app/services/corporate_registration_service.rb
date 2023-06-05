class CorporateRegistrationService
  include SecretKeyHooks

  
  def initialize(params)
    @user = params[:user]
    @email = params[:email]
    @first_name = params[:first_name]
    @last_name = params[:last_name]
    @phone_number = params[:phone_number]
    @profile_type = params[:profile_type]
    @business_name = params[:business_name]
    @industry = params[:industry]
    @country_of_incorporation = params[:country]
    @staff_strength = params[:staff_strength]
    @role_at_business = params[:role_at_business]
    @website = params[:website]
    @registration_status = params[:registration_status]
  end

  # Service entry point
  def call
    ActiveRecord::Base.transaction do
      existing_profile = Profile.find_by(user_id: @user.id)

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

      if profile.profile_type == "business"
        business = Business.create!(
          business_name: @business_name,
          industry: @industry,
          country_of_incorporation: @country_of_incorporation,
          staff_strength: @staff_strength,
          role_at_business: @role_at_business,
          registration_status: @registration_status,
          website: @website,
          profile: profile,
          is_live: true,
          api_key: generate_live_key[:business],
          test_key: generate_test_key[:business],
        )
      end

      # create a live wallet
      Wallet.create(
        profile_id: profile.id,
        business_id: business.id,
        cleared_balance: 0.00,
        available_balance: 0.00,
        profile_type: 'business'
      )

       # create a test wallet
       Wallet.create(
        profile_id: profile.id,
        business_id: business.id,
        cleared_balance: 0.00,
        available_balance: 0.00,
        profile_type: 'business',
        is_test: true
      )


      # create default business team
     business_team =  BusinessTeam.create!(
        business: business,
        profile: profile
      )

      # create default business team admin memeber
      BusinessTeamMember.create!(
        business_team: business_team,
        role: 'admin',
        profile: profile
      )


    end
  end

  private

end