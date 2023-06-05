class AddTestKeyToBusiness < ActiveRecord::Migration[6.1]
  def up
    add_column :businesses, :test_key, :string
  end

  def down
    remove_column :businesses, :test_key, :string
  end
end
