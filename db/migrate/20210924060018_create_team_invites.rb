class CreateTeamInvites < ActiveRecord::Migration[6.1]
  def change
    create_table :team_invites do |t|
      t.string :code
      t.string :email
      t.references :business, null: false, foreign_key: true
      t.references :business_team, null: false, foreign_key: true
      t.column :role, :integer

      t.timestamps
    end
  end
end
