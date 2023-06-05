class TransactionLog < ApplicationRecord
  belongs_to :profile
  belongs_to :wallet, optional: true
  belongs_to :wallet_history, optional: true
  belongs_to :ledger, optional: true
  belongs_to :ledger_history, optional: true
  has_many :orders

  validates_presence_of :reference_id, :gift_card_code, :log_type, :status

  enum status: {
    pending: 0,
    success: 10,
    failed: 20,
    test: 30,
    delivered: 40,
    abandoned: 50
  }

  # for future use
  # transaction type is currently used as string
  enum log_type: {
    send: 0,
    reload: 10,
    redeem: 20,
    credit: 30,
    airtime: 40,
    cabletv: 50,
    electricbill: 60,
    epin: 70
  }, _suffix: true
end
