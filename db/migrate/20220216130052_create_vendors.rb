class CreateVendors < ActiveRecord::Migration[6.1]
  def change
    create_table :vendors do |t|
      t.string :business_name
      t.references :profile, null: false, foreign_key: true
      t.string :industry
      t.string :registration_status
      t.string :country_of_incorporation
      t.boolean :is_live, default: true, null: false
      t.string :live_key
      t.string :test_key
      t.boolean :is_authorised, default: false

      t.timestamps
    end
  end
end
