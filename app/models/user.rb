class User < ApplicationRecord
  extend Devise::Models #added this line to extend devise model

  after_validation :ensure_uid_is_present
  #after_commit :send_pending_notifications
  
  # Include default devise modules.
  devise :database_authenticatable, :registerable,
          :recoverable, :rememberable, :trackable, :validatable,
          :confirmable 
          # :omniauthable

  # before_save :ensure_authentication_token
  has_many :profiles
  # has_one :business, through: :profiles
  has_one :business_teams

  # scope :user_by_api_key, ->(api_key) { profiles.where("profile_type = ?", "business").first.business.where("api_key = ?", api_key).user }

  include DeviseTokenAuth::Concerns::User
  # before_save -> { skip_confirmation! }
  # def wallet(profile_type)
  #   profiles.where(profile_type: profile_type).first.wallets.where(profile_type: profile_type).first
  # end

  # def profile(profile_type)
  #   profiles.where(profile_type: profile_type).first
  # end

  def user_by_api_key(api_key)
    profile.where("profile_type = ?", "business").first
    .business.where("api_key = ?", api_key)
    .user
  end

  private

  def send_devise_notification(notification, *args)
    # If the record is new or changed then delay the
    # delivery until the after_commit callback otherwise
    # send now because after_commit will not be called.
    # if new_record? || changed?
    #   pending_notifications << [notification, args]
    # else
    #   devise_mailer.send(notification, self, *args).deliver
    # end

    if ENV['RAILS_ENV'] != 'production'
      devise_mailer.send(notification, self, *args).deliver
    else
      devise_mailer.send(notification, self, *args).deliver_later
    end

  end

  def send_pending_notifications
    pending_notifications.each do |notification, args|
      devise_mailer.send(notification, self, *args).deliver
    end

    # Empty the pending notifications array because the
    # after_commit hook can be called multiple times which
    # could cause multiple emails to be sent.
    pending_notifications.clear
  end

  def pending_notifications
    @pending_notifications ||= []
  end

  def ensure_uid_is_present
    return unless self.uid.blank?

    self.uid = generate_uid
  end

  def generate_uid
    loop do
      uid = SecureRandom.uuid
      break uid unless User.find_by(uid: uid)
    end
  end
end
