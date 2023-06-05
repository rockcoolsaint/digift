class PersonalRegistrationService
  def initialize(params)
    @user = params[:user]
    @email = params[:email]
    @first_name = params[:first_name]
    @last_name = params[:last_name]
    @phone_number = params[:phone_number]
    @profile_type = params[:profile_type]
  end

  def call
    ActiveRecord::Base.transaction do
      existing_profile = Profile.find_by(user_id: @user.id)

      # cannot have more than 2 profiles
      # if profile exists for the current user_id && the profile hash length is <= 2
      if !existing_profile || !(existing_profile.profile_type === @profile_type)
        profile = Profile.create!(
        first_name: @first_name,
        last_name: @last_name,
        phone_number: @phone_number,
        profile_type: @profile_type,
        user_id: @user.id )
      elsif existing_profile && existing_profile.profile_type === @profile_type # prevent from creating multiple profiles of the same type
        raise(ExceptionHandler::InvalidProfileType, "You probably already have a #{@profile_type} profile type")
      end
    end
  end

  private

end