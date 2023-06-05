class CreatePromoWinners < ActiveRecord::Migration[6.1]
  def change
    create_table :promo_winners do |t|
      t.references :promo, null: true
      t.references :profile, null: false
      t.uuid :transaction_log_id, null: true
      t.boolean :is_active, null: false, default: false
      t.boolean :is_expired, null: false, default: false
      t.boolean :is_completed, null: false, default: false


      t.timestamps
    end
  end
end
