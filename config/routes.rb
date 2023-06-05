Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  #mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'


  mount_devise_token_auth_for 'User', at: 'auth', controllers: {
    registrations: 'overrides/registrations',
    confirmations: 'overrides/confirmations',
    passwords: 'overrides/passwords',
    sessions: 'overrides/sessions',
    token_validations: 'overrides/token_validations'
  }

  mount_devise_token_auth_for 'Admin', at: 'admin_auth', controllers: {
    registrations: 'overrides/admin/registrations',
    confirmations: 'overrides/confirmations',
    passwords: 'overrides/passwords',
    sessions: 'overrides/admin/sessions',
    token_validations: 'overrides/token_validations'
  }

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root "home#index"

  devise_scope :user do
    post 'auth/register/business', to: 'overrides/corporate/registrations#create'
    post 'auth/register/business/team-member', to: 'overrides/corporate/team_members_registrations#create'
    post 'auth/register/personal', to: 'overrides/personal/registrations#create'
    patch 'auth/settings',         to: 'overrides/settings#update'
    get  'auth/me',               to: 'api/v1/user_actions#me'
    post 'auth', to: redirect('/auth/register/personal')
    put 'auth', to: redirect('/auth/settings')
    post "admin/register/vendor", to: "overrides/corporate/vendor_registrations#create"
  end
  namespace :api, defaults: { format: 'json' } do
    namespace :v1 do
      get "/available-giftcards", to: "gift_card_actions#fetch"
      post "/available-giftcards", to: "gift_card_actions#index"

      get "/available-giftcards/local", to: "suregifts_card_actions#fetch"
      post "/available-giftcards/local", to: "suregifts_card_actions#index"

      post "/gift-cards/send_retail/sgc",    to: "suregifts_card_actions#send_retail_card"

      get "/available-giftcards/custom", to: "custom_gift_card_actions#index"
      get "/business/custom/giftcards", to: "custom_gift_card_actions#show"
      post "/business/custom/giftcards", to: "custom_gift_card_actions#create"
      put "/business/custom/giftcards/:code", to: "custom_gift_card_actions#update"
      
      post "/gift-cards/send",    to: "gift_card_actions#send_card"
      post "/gift-cards/send/vendor",    to: "gift_card_actions#vendor_send_card"
      post "/gift-cards/send_retail",    to: "gift_card_actions#send_retail_card"

      post "/gift-cards/send_tmp_retail",    to: "gift_card_actions#send_tmp_retail_card"
      post "/generate-fundwallet-reference", to: "transaction_actions#create_fund_wallet"
      post "/verify-fundwallet-reference", to: "transaction_actions#verify_fund_wallet"
      post "/verify-fundwallet-reference/paystack", to: "transaction_actions#paystack_verify_fund_wallet"
      post "/generate-transaction-reference", to: "transaction_actions#create_make_transaction"
      post "/generate-transaction-reference/:type", to: "transaction_actions#create_new_transaction"
      post "/generate-tmp-transaction-reference", to: "transaction_actions#create_make_tmp_transaction"
      post "/verify-transaction-reference", to: "transaction_actions#verify_make_transaction"
      post "/verify-transaction-reference/paystack", to: "transaction_actions#paystack_verify_make_transaction"
      post "/cancel-transaction-reference/paystack", to: "transaction_actions#paystack_cancel_make_transaction"
      get  '/business/wallet', to: 'user_actions#my_wallet'
      get "/fetch-send-transactions", to: "transaction_actions#fetch_send_transactions"
      patch "/business/go-live", to: "user_actions#go_live"
      get "/business/keys", to: "user_actions#fetch_keys"
      patch "/business/keys", to: "user_actions#patch_keys"
      get "/business/team", to: "user_actions#fetch_team_members"
      post "/business/fxrates", to: "fx_actions#index"
      get "/fxrates", to: "fx_actions#get_web_rates"
      post "/business/send-team-invite", to: "invite_actions#send_team_invite_email"
      get "/business/verify-team-invite", to: "invite_actions#verify_team_invite_email"
      get "/business/team-member/role", to: "invite_actions#get_invite_roles"
      delete "/business/team-member/remove/:memberId", to: "invite_actions#remove_business_team_member"
      get "/cart", to: "cart_actions#index"
      post "/gift-cards/send_retail/cart", to: "gift_card_actions#send_retail_cards_for_cart"
      post "/cart/:cart_id/item", to: "cart_actions#add_cart_item"
      put "/cart/:cart_id/item/:cart_item_id", to: "cart_actions#update_cart_item"
      delete "/cart/:cart_id/item/:cart_item_id", to: "cart_actions#delete_cart_item"
      post "/purchase/airtime", to: "airtime_actions#purchase_airtime"
      post "/utility/account/validation", to: "utility_actions#utility_account_verify"
      post "/utility/cabletv/bouquets", to: "utility_actions#utility_providers_bouquets"
      post "/utility/cabletv/addons", to: "utility_actions#utility_providers_bouquets_addons"
      get "/utility/cabletv/service-type", to: "utility_actions#get_service_types"
      post "/utility/cabletv/renewal", to: "utility_actions#utility_renewal"
      post "/utility/cabletv/change-subscription", to: "utility_actions#utility_change_subscription"
      get "/utility/electricity/billers", to: "utility_actions#utility_electricity_providers"
      post "/utility/electricbill/payment", to: "utility_actions#utility_pay_electric"

      get "/promo-count", to: "transaction_actions#get_promo_winner"
      get "/utility/epin/providers", to: "utility_actions#epin_service_providers"
      post "/utility/epin/retrieve/bundles", to: "utility_actions#epin_bundle_retrieval"
      post "/utility/epin/request", to: "utility_actions#epin_purchase"
      get "/giftcards/categories", to: "giftcard_category_actions#index"
    end
  end


  devise_scope :admin do
    # Define routes for Admin within this block.
      get "admin/fxrates", to: "api/v1/admin_actions#fetch"
      post "admin/fxrates", to: "api/v1/admin_actions#index"
      patch "admin/fxrates/:fx_id", to: "api/v1/admin_actions#update"
      get "admin/fxrates/history", to: "api/v1/admin_actions#fetch_fx_history"
      post 'admin/register/user', to: 'overrides/admin/users_registrations#create'
      get "admin/users", to: "api/v1/admin_actions#users_index"
      get "admin/customers", to: "api/v1/admin_actions#customers_index"
      get "admin/transactions", to: "api/v1/admin_actions#transactions_index"
    
      get "admin/business/custom/giftcards", to: "api/v1/admin_actions#custom_giftcard_index"
      put "admin/business/custom/giftcards/:code", to: "api/v1/admin_actions#disable_custom_giftcard"
     
      post "admin/send-admin-invite", to: "api/v1/admin_actions#send_admin_invite_email"
      get "admin/verify-admin-invite/:invite_code", to: "api/v1/admin_actions#verify_admin_invite_email"
      get "admin/user/roles", to: "api/v1/admin_actions#get_invite_roles"

      get "admin/giftcards/categories", to: "api/v1/admin_category_actions#index"
      post "admin/giftcards/category", to: "api/v1/admin_category_actions#create"
      patch "admin/giftcards/category/:id", to: "api/v1/admin_category_actions#update"
      # get "admin/giftcards/category-items", to: "api/v1/admin_category_actions#index"
      post "admin/giftcards/category-item", to: "api/v1/admin_category_item_actions#create"
      patch "admin/giftcards/category-item/:id", to: "api/v1/admin_category_item_actions#update"
      post "admin/vendor/add/giftcard/source", to: "api/v1/admin_actions#set_vendor_giftcard_source"
      put "admin/vendor/update/giftcard/source", to: "api/v1/admin_actions#update_vendor_giftcard_source"
  end
end
