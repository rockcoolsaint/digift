class AddTestModeToProfiles < ActiveRecord::Migration[6.1]
  def change
    add_column :profiles, :test_mode, :boolean, :null => false, :default => true
  end
end
