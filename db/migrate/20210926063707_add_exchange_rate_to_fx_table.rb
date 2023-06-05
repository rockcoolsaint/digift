class AddExchangeRateToFxTable < ActiveRecord::Migration[6.1]
  def up
    add_column :fxes, :__type, :string, if_not_exists: true, default: "fx:#"
    add_column :fxes, :exchange_rate, :decimal, if_not_exists: true
    change_column :fxes, :rate, :decimal, null: false, if_not_exists: true, default: 0
    add_column :fxes, :is_public, :boolean, null: false, if_not_exists: true, default: false
  end

  def down
    remove_column :fxes, :exchange_rate, :decimal, if_not_exists: true
    remove_column :fxes, :rate, :decimal, null: false, if_not_exists: true, default: 0
    remove_column :fxes, :__type, :string, if_not_exists: true, default: "fx:#"
    remove_column :fxes, :is_public, :boolean, null: false, if_not_exists: true, default: false
  end
end
