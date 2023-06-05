class AddLedgerAndLedgerHistoryColumnToTransactionLog < ActiveRecord::Migration[6.1]
  def up
    add_column :transaction_logs, :ledger_id, :uuid, :null => true,  if_not_exists: true
    add_column :transaction_logs, :ledger_history_id, :uuid, :null => true,  if_not_exists: true
  end
  def down
    remove_column :transaction_logs, :ledger_id, :uuid, :null => true, if_exists: true
    remove_column :transaction_logs, :ledger_history_id, :uuid, :null => true, if_exists: true
  end
end
