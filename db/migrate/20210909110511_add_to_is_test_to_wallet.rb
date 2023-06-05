class AddToIsTestToWallet < ActiveRecord::Migration[6.1]
  def up
    add_column :wallets, :is_test, :boolean, :null => false, :default => false
  end

  def down
    remove_column :wallets, :is_test, :boolean, :null => false, :default => false
  end
end
