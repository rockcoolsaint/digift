class CreateFxHistories < ActiveRecord::Migration[6.1]
  def change
    create_table :fx_histories do |t|
      t.references :fx, null: false, foreign_key: true
      t.references :profile, null: false, foreign_key: true, optional: true
      t.decimal :current_rate, null: false, precision: 30, scale: 2
      t.decimal :previous_rate, null: false, precision: 30, scale: 2
      t.decimal :current_exchange_rate, null: false, precision: 30, scale: 2
      t.decimal :previous_exchange_rate, null: false, precision: 30, scale: 2

      t.timestamps
    end
  end
end
