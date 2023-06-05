class AddTransactionLogTypeToLogTypeTransactioNLog < ActiveRecord::Migration[6.1]
  def up
    # add_column :profiles, :bvn, :string, default: :null, null: false
    add_column :transaction_logs, :transaction_log_type, :integer, default: 0, null: false, if_not_exists: true
  end

  def down
    # remove_column :profiles, :bvn, :string, default: :null, null: false
    remove_column :transaction_logs, :transaction_log_type, :integer, default: 0, null: false, if_not_exists: true
  end
end
