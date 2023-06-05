class CreateBusinessTeamMembers < ActiveRecord::Migration[6.1]
  def change
    create_table :business_team_members do |t|
      t.references :profile, null: false, foreign_key: true
      t.references :business_team, null: false, foreign_key: true
      t.boolean :is_active, default: true
      t.column :role, :integer, default: 1


      t.timestamps
    end
  end
end
