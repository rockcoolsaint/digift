class CreateVendorAllowedGiftcardSources < ActiveRecord::Migration[6.1]
  def change
    create_table :vendor_allowed_giftcard_sources do |t|
      t.references :vendor, null: false, foreign_key: true
      t.string :sources, array: true
      t.references :created_by, index: true, foreign_key: {to_table: :admins}
      t.boolean :is_active, default: true, null: false

      t.timestamps
    end
  end
end
