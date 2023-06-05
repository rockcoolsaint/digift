class CreateLedgerHistories < ActiveRecord::Migration[6.1]
  def change
    create_table :ledger_histories, id: :uuid do |t|
      t.references :ledger, null: false, foreign_key: true, type: :uuid
      t.references :vendor, null: false, foreign_key: true
      t.references :profile, null: false, foreign_key: true
      t.jsonb :sender_details
      t.string :preference
      t.string :type
      t.jsonb :details
      t.string :category
      t.decimal :balance, precision: 30, scale: 2
      t.decimal :amount, precision: 30, scale: 2
      t.decimal :actual_amount, precision: 30, scale: 2
      t.string :description
      t.string :reference_code
      t.string :channel
      t.boolean :status, default: false
      t.boolean :is_active, default: false, null: false

      t.timestamps
    end
  end
end
