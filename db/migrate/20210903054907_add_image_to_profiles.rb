class AddImageToProfiles < ActiveRecord::Migration[6.1]
  def up
    add_column :profiles, :image, :string
  end

  def down
    remove_column :profiles, :image
  end
end
