require 'rails_helper'

RSpec.describe TransactionLog, type: :model do
  it { should belong_to(:profile) }
  it { should belong_to(:wallet) }
  it { should belong_to(:wallet_history) }
  it { should have_many(:orders) }

  it { should validate_presence_of(:reference_id) }
  it { should validate_presence_of(:gift_card_code) }
  it { should validate_presence_of(:log_type) }
  it { should validate_presence_of(:status) }
end
