class CreateCategories < ActiveRecord::Migration[6.1]
  def change
    create_table :categories do |t|
      t.string :title
      t.boolean :is_active, default: true
      t.integer :category_item_id
      t.references :admin, null: false, foreign_key: true

      t.timestamps
    end
  end
end
