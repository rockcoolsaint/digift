class AdminGiftCardsCategoryItemAdminSerializer < ActiveModel::Serializer
  attributes :id, :email, :role, :status


  def role
    object.role
  end

  def status
    status_value = "inactive"
    status_value = "active" if object.try(:is_active )
    status_value
  end
end