class FxrateSerializer < ActiveModel::Serializer
  attributes  :__type, :currency, :currency_symbol, :iso, :rate, :exchange_rate
end
