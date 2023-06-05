class AddDefaulToLogTypeTransactioNLog < ActiveRecord::Migration[6.1]
  def change
    change_column_default(:transaction_logs, :log_type, 0)
  end
end
