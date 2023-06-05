class FxHistorySerializer < ActiveModel::Serializer
  attributes :id, :current_exchange_rate, :created_at

  belongs_to :admin

  def admin
    object.admin.email
  end
end
