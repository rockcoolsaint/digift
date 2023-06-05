class CreateWallets < ActiveRecord::Migration[6.1]
  def change
    create_table :wallets, id: :uuid do |t|
      t.references :profile, null: false, foreign_key: true
      t.decimal :cleared_balance, precision: 30, scale: 2, default: 0.00
      t.decimal :available_balance, precision: 30, scale: 2, default: 0.00
      t.boolean :is_active
      t.string :profile_type

      t.timestamps
    end
  end
end
