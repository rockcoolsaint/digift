class AddBusinessIdToWallet < ActiveRecord::Migration[6.1]
  def up
    add_reference :wallets, :business, foreign_key: true, :null => true
  end

  def down
    remove_reference :wallets, :business, foreign_key: true, :null => true
  end
end
