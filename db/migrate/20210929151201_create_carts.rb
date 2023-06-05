class CreateCarts < ActiveRecord::Migration[6.1]
  def change
    create_table :carts, id: :uuid do |t|
      t.references :profile, null: false, foreign_key: true
      t.boolean :checked_out, default: false, null: false
      t.boolean :is_active, default: true, null: false

      t.timestamps
    end
  end
end
