class AddisDisabledColumntoCustomGiftCards < ActiveRecord::Migration[6.1]
  def up
    add_column :custom_gift_cards, :is_disabled, :boolean, default: false, null: true, if_not_exists: true
  end

  def down
    remove_column :custom_gift_cards, :is_disabled, :boolean, default: false, null: true, if_not_exists: true
  end
end
