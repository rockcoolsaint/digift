class ChangeProfileColumnOnFxHistory < ActiveRecord::Migration[6.1]
  def up
    remove_reference :fx_histories, :profile, foreign_key: true
    add_reference :fx_histories, :admin, null: false, foreign_key: true
  end

  def down
    add_reference :fx_histories, :profile, null: false, foreign_key: true
    remove_reference :fx_histories, :admin, foreign_key: true
  end
end
