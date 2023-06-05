class AddExchangeRatesToFxHistory < ActiveRecord::Migration[6.1]
  def up
    add_column :fx_histories, :previous_exchange_rate, :decimal, null: false, if_not_exists: true, precision: 30, scale: 2
    add_column :fx_histories, :current_exchange_rate, :decimal, null: false, if_not_exists: true, precision: 30, scale: 2
  end

  def down
    remove_column :fx_histories, :previous_exchange_rate, :decimal, null: false, if_not_exists: true, precision: 30, scale: 2
    remove_column :fx_histories, :current_exchange_rate, :decimal, null: false, if_not_exists: true, precision: 30, scale: 2
  end
end
