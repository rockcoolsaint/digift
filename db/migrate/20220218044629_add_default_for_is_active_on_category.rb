class AddDefaultForIsActiveOnCategory < ActiveRecord::Migration[6.1]
  def change
    change_column_null :categories, :is_active, false
    change_column_null :category_items, :is_active, false
  end
end
