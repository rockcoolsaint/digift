class ChangeApiKeyToNullableBusiness < ActiveRecord::Migration[6.1]
  def up
    change_column :businesses, :api_key, :string, :null => true
  end

  def down
    remove_column :businesses, :test_key, :string, :null => true
  end
end

