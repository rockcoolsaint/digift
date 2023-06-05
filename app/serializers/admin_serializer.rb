class AdminSerializer < ActiveModel::Serializer
  attributes :id, :email, :role, :date_created, :status, :created_by


  def role
    object.role
  end

  def date_created
    object.created_at
  end

  def status
    status_value = "inactive"
    status_value = "active" if object.try(:is_active )
    status_value
  end
  def created_by
    object.created_by
  end
end
