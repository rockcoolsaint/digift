class AddCartIdToTransactionLog < ActiveRecord::Migration[6.1]
  def up
    add_reference :transaction_logs, :cart, type: :uuid, null: true, foreign_key: true, optional: true
  end

  def down
    remove_reference :transaction_logs, :cart, type: :uuid, null: true, foreign_key: true, optional: true
  end
end
