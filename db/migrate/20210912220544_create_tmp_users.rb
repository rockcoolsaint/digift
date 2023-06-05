class CreateTmpUsers < ActiveRecord::Migration[6.1]
  def change
    create_table :tmp_users do |t|
      t.string :email
      t.string :password
      t.string :phone_number
      t.string :tmp_token

      t.timestamps
    end
  end
end
