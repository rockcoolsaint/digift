class AddRoleIsActiveCreatedBytoAdmin < ActiveRecord::Migration[6.1]
  def up
    add_column :admins, :role, :integer, default: 3, null: true, if_not_exists: true
    add_column :admins, :created_by, :string, default: "", null: true, if_not_exists: true
    add_column :admins, :is_active, :boolean, default: true, null: true, if_not_exists: true
  end

  def down
    remove_column :admins, :role, :integer, default: 3, null: true, if_not_exists: true
    remove_column :admins, :created_by, :string, default: "", null: true, if_not_exists: true
    remove_column :admins, :is_active, :string, default: true, null: true, if_not_exists: true
  end
end
