class CreateCartItems < ActiveRecord::Migration[6.1]
  def change
    create_table :cart_items, id: :uuid  do |t|
      t.references :cart, null: false, foreign_key: true, type: :uuid
      t.integer :value, null: false, default: 0
      t.boolean :is_active, null: false, default: true
      t.integer :quantity, null: false, default: 0
      t.string :card_code, null: false
      t.boolean :checked_out, null: false, default: false
      t.boolean :is_deleted, null: false, default: false

      t.timestamps
    end
  end
end
