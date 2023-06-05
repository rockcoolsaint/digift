class CreatePromos < ActiveRecord::Migration[6.1]
  def change
    create_table :promos do |t|
      t.integer :final_count, default: 100
      t.integer :current_count, default: 0
      t.boolean :is_active, null: false, default: false
      t.decimal :discount, null: false, default: 0.5
      t.string :title, null: true, default: ''
      t.datetime :start_date, null: false, default: Time.now.beginning_of_day
      t.datetime :end_date, null: false, default: 7.day.from_now.end_of_day

      t.timestamps
    end
  end
end
