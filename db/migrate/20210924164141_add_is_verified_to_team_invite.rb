class AddIsVerifiedToTeamInvite < ActiveRecord::Migration[6.1]
  def up
    add_column :team_invites, :is_verified,  :boolean, :null => false, :default => false
  end

  def down
    remove_column :team_invites, :is_verified,  :boolean, :null => false, :default => false
  end
end
