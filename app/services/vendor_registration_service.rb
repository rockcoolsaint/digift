class VendorRegistrationService
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

      if profile.profile_type == "vendor"
        vendor = Vendor.create!(
          business_name: @business_name,
          industry: @industry,
          country_of_incorporation: @country_of_incorporation,
          registration_status: @registration_status,
          profile: profile,
          is_live: true,
          live_key: generate_live_key[:vendor],
          test_key: generate_test_key[:vendor],
        )
      end

      # create a live ledger
      Ledger.create(
        profile_id: profile.id,
        vendor_id: vendor.id,
        debit: 0.0,
        credit: 0.0,
        balance: 0.0
      )

       # create a test ledger
       Ledger.create(
        profile_id: profile.id,
        vendor_id: vendor.id,
        credit: 0.0,
        debit: 0.0,
        balance: 0.0,
        is_test: true
      )


      # create default business team
    #  business_team =  BusinessTeam.create!(
    #     business: business,
    #     profile: profile
    #   )

    #   # create default business team admin memeber
    #   BusinessTeamMember.create!(
    #     business_team: business_team,
    #     role: 'admin',
    #     profile: profile
    #   )

    @user.skip_confirmation!
    @user.save
    end
  end

  private

end 