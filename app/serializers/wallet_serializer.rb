class WalletSerializer < ActiveModel::Serializer
  attributes :cleared_balance, :available_balance, :is_test
  # belongs_to :profile
  # belongs_to :business

  def filter
    object.map do |wallet|
      {
        cleared_balance: wallet.cleared_balance,
        available_balance: wallet.available_balance,
        is_test: wallet.is_test
      }
    end
  end

end
