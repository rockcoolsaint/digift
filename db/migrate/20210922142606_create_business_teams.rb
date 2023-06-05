class CreateBusinessTeams < ActiveRecord::Migration[6.1]
  def change
    create_table :business_teams do |t|
      t.references :profile, null: false, foreign_key: true
      t.references :business, null: false, foreign_key: true
      t.boolean :is_active, default: true
      t.string :team_name, default: "My Team"

      t.timestamps
    end
  end
end
