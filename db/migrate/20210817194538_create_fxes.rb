class CreateFxes < ActiveRecord::Migration[6.1]
  def change
    create_table :fxes do |t|
      t.string :__type, null: true, default: "fx:#"
      t.string :name
      t.string :currency
      t.string :currency_symbol
      t.string :iso
      t.decimal :rate, null: false, default: 0.00, precision: 30, scale: 2
      t.decimal :exchange_rate , null: false, default: 0.00, precision: 30, scale: 2
      t.boolean :is_active, null: false, default: true
      t.boolean :is_public, null: false, default: false

      t.timestamps
    end
  end
end
