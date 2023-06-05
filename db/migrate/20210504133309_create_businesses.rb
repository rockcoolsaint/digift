class CreateBusinesses < ActiveRecord::Migration[5.2]
  def change
    create_table :businesses do |t|
      t.string :business_name
      t.references :profile, foreign_key: true
      t.string :industry
      t.string :country_of_incorporation
      t.string :staff_strength
      t.string :registration_status
      t.string :role_at_business
      t.string :website

      t.timestamps
    end
  end
end
