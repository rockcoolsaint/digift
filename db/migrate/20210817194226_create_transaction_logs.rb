class CreateTransactionLogs < ActiveRecord::Migration[6.1]
  def change
    create_table :transaction_logs, id: :uuid do |t|
      t.references :profile, null: false, foreign_key: true
      t.string :gift_card_code
      t.jsonb :details
      t.integer :log_type
      t.integer :status, default: 0
      t.boolean :is_active
      t.uuid :reference_id
      t.decimal :amount, precision: 30, scale: 2
      t.jsonb :transaction_rate
      t.uuid :wallet_id
      t.uuid :wallet_history_id

      t.timestamps
    end

    add_index :transaction_logs, :wallet_id
    add_index :transaction_logs, :wallet_history_id
  end
end
