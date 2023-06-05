class Fx < ApplicationRecord


  has_many :fx_histories


  def self.get_rate
    find_by("currency = ? OR name = ?", ENV['FX_CURRENCY'],  'naira').rate
  rescue
    ENV['FX_RATE']
  end
end
