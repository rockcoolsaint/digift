class Order < ApplicationRecord
  belongs_to :profile
  belongs_to :transaction_log

  ORDER_TYPES = ['send', 'reload', 'redeem', 'credit']
  ORDER_STATUS = ['success', 'failed', 'test']
end
