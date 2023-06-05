class AddDetailsToBusinesses < ActiveRecord::Migration[6.1]
  def change
    add_column :businesses, :api_key, :string
    add_column :businesses, :is_live, :boolean, default: false
  end
end
