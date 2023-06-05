class CreateCustomGiftCards < ActiveRecord::Migration[6.1]
  def change
    create_table :custom_gift_cards do |t|
      t.string :__type, default: "type"
      t.string :caption
      t.string :code
      t.string :color, default: "#0277fe"
      t.string :currency, default: "NGN"
      t.string :desc
      t.string :disclosures
      t.decimal :discount, default: 0.0
      t.string :domain
      t.string :fee, default: 100.0
      t.string :fontcolor, default: "#FFFFFF"
      t.boolean :is_variable, default: false
      t.string :iso, default: "ng"
      t.string :logo
      t.integer :max_range, default: 0.0
      t.integer :min_range, default: 0.0
      t.string :sendcolor, default: "#FFFFFF"
      t.integer :values, array: true
      t.references :business
      t.references :profile
      t.boolean :is_active, default: true

      t.timestamps
    end
    add_index :custom_gift_cards, :values, using: 'gin'
  end
end
