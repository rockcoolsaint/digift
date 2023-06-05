class AddBvnToProfile < ActiveRecord::Migration[6.1]
  def up
    add_column :profiles, :bvn, :string, default: :null, null: false
    add_column :profiles, :is_verified, :boolean, default: :false, null: false
  end

  def down
    remove_column :profiles, :bvn, :string, default: :null, null: false
    remove_column :profiles, :is_verified, :boolean, default: :false, null: false
  end
end
