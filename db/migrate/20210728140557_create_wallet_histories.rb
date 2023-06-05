class CreateWalletHistories < ActiveRecord::Migration[6.1]
  def change
    create_table :wallet_histories, id: :uuid do |t|
      t.references :profile, null: false, foreign_key: true
      t.jsonb :sender_details
      t.string :preference
      t.string :type
      t.jsonb :details
      t.string :category
      t.decimal :amount, precision: 30, scale: 2
      t.decimal :balance, precision: 30, scale: 2
      t.decimal :commission, precision: 30, scale: 2
      t.decimal :actual_amount, precision: 30, scale: 2
      t.string :description
      t.string :reference_code
      t.string :channel
      t.boolean :status, default: false
      t.boolean :is_active
      t.uuid :wallet_id

      t.timestamps
    end

    add_index :wallet_histories, :wallet_id
  end
end
