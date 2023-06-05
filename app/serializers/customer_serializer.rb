class CustomerSerializer < ActiveModel::Serializer
  attributes :id, :first_name, :last_name, :email, :phone_number, :profile_type, :image, :test_mode, :bvn, :is_verified, :last_login, :last_transaction


  # belongs_to :user
  # has_many :transaction_logs



  def last_login
    object.user.last_sign_in_at  
  end
  def email
    object.user.email
  end

  def last_transaction
    sorted_logs = object.transaction_logs.sort { |a,b| a.created_at <=> b.created_at }
    sorted_logs.first.try(:[], "created_at")
  end
end
