class ChangeWalletToNullOnTransactions < ActiveRecord::Migration[6.1]
  def change
    change_column :transaction_logs, :wallet_id, :uuid, :null => true
    change_column :transaction_logs, :wallet_history_id, :uuid, :null => true
  end
end


