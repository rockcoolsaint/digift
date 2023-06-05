class AddColumFromTransactionItemName < ActiveRecord::Migration[6.1]
  def up
    add_column :transaction_logs, :gift_card_name, :string, default: "", null: true, if_not_exists: true
  end

  def down
    remove_column :transaction_logs, :gift_card_name, :string, default: "", null: true, if_not_exists: true
  end
end
