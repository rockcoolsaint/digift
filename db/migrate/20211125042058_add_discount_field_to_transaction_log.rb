class AddDiscountFieldToTransactionLog < ActiveRecord::Migration[6.1]
  def up
    # add_column :profiles, :bvn, :string, default: :null, null: false
    add_column :transaction_logs, :is_discounted, :boolean, default: false, null: false, if_not_exists: true
    add_column :transaction_logs, :discount_rate, :decimal, default: 0.0, null: true, if_not_exists: true
  end

  def down
    # remove_column :profiles, :bvn, :string, default: :null, null: false
    remove_column :transaction_logs, :is_discounted, :boolean, default: false, null: false, if_not_exists: true
    remove_column :transaction_logs, :discount_rate, :decimal, default: 0.0, null: true, if_not_exists: true
  end
end
