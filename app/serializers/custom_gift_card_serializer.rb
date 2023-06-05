class CustomGiftCardSerializer < ActiveModel::Serializer
  attributes :__type, :caption, :captionLower, :code, :color, :currency, :desc, :disclosures, :discount, :data, :domain, :fee, :fontcolor, :is_variable, :iso, :logo, :max_range, :min_range, :sendcolor, :value

  def captionLower
    object.caption.try(:downcase)
  end

  def value
    object.values.join(',')
  end

  def data
    value = []
    for item in object.values do
      value << "#{item}:#{object.fee}"
    end
    "#{object.min_range}|#{value.join(",")}|#{object.currency}"
  end

  def logo
    object.logo.url
  end
end
