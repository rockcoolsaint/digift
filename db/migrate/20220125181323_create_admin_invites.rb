class CreateAdminInvites < ActiveRecord::Migration[6.1]
  def change
    create_table :admin_invites do |t|
      t.string :code
      t.string :email
      t.integer :role
      t.boolean :is_verified
      t.references :admin, null: false, foreign_key: true

      t.timestamps
    end
  end
end
