class CreateCategoryItems < ActiveRecord::Migration[6.1]
  def change
    create_table :category_items do |t|
      t.string :item_id
      t.integer :category_id
      t.string :item_name
      t.boolean :is_active, default: true

      t.timestamps
    end
  end
end
