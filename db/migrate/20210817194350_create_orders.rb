class CreateOrders < ActiveRecord::Migration[6.1]
  def change
    create_table :orders, id: :uuid do |t|
      t.string :card_order_id, null: false
      t.decimal :total_amount, null: false, default: 0.00, precision: 30, scale: 2
      t.decimal :amount, null: false, default: 0.00, precision: 30, scale: 2
      t.integer :quantity, null: false, default: 0
      t.string :gift_card_code, null: false
      t.jsonb :details, default: '{}'
      t.string :order_type, null: false
      t.string :status, null: false
      t.boolean :is_active
      t.references :profile, null: false, foreign_key: true
      t.uuid :transaction_log_id

      t.timestamps
    end

    add_index :orders, :transaction_log_id
  end
end
