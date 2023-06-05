class UpdateBvnDefaultProfile < ActiveRecord::Migration[6.1]
  def change
    change_column_null(:profiles, :bvn,  true)
    change_column_default(:profiles, :bvn,  nil)
  end
end

