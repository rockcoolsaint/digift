class AdminUsersInviteRegistrationService
  def initialize(params)
    @admin = params[:admin]
    # @email = params[:email]
    # @first_name = params[:first_name]
    # @last_name = params[:last_name]
    # @phone_number = params[:phone_number]
    # @profile_type = params[:profile_type]
    @invite_code = params[:invite_code]
  end

  # Service entry point
  def call
    ActiveRecord::Base.transaction do
      invite = AdminInvite.where(code: @invite_code , is_verified: true)
      raise(ExceptionHandler::InvalidProfileType, "your invite token is no longer valid/does not exist, please request a new invite") unless invite.exists?
      invite = AdminInvite.find_by(code: @invite_code )
      @admin.update!(role: invite.role, created_by: invite.admin.email)
      invite.destroy
    end
  end

  private

end