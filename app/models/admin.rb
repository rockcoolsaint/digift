# frozen_string_literal: true

class Admin < ApplicationRecord
  extend Devise::Models #added this line to extend devise model

  # after_validation :ensure_uid_is_present
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :confirmable
  include DeviseTokenAuth::Concerns::User

  before_save -> { skip_confirmation! }

  has_many :fx_histories

  enum role: {
    admin: 0,
    finance: 1,
    hyper_admin: 2,
    other: 3
  }

  private

  def ensure_uid_is_present
    return unless self.uid.blank?

    self.uid = generate_uid
  end

  def generate_uid
    loop do
      uid = SecureRandom.uuid
      break uid unless Admin.find_by(uid: uid)
    end
  end
end
