class CreateLedgers < ActiveRecord::Migration[6.1]
  def change
    create_table :ledgers, id: :uuid do |t|
      t.references :profile, null: false, foreign_key: true
      t.references :vendor, null: false, foreign_key: true
      t.decimal :debit, null: false, default: 0.0, precision: 30, scale: 2
      t.decimal :credit, null: false, default: 0.0, precision: 30, scale: 2
      t.decimal :balance, null: false, default: 0.0, precision: 30, scale: 2
      t.boolean :use_credit, default: false
      t.boolean :is_test, default: false
      t.boolean :is_active, default: true, null: false

      t.timestamps
    end
  end
end
