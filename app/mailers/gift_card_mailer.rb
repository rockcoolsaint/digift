class GiftCardMailer < ApplicationMailer
  def voucher_purchase_notification(to_address, reference, logo, caption, valid_address)
    @to_address = to_address
    @reference = reference
    @logo = logo
    @caption = caption
    @valid_address = valid_address
    mail(to: @to_address, subject: "You successfully purchased a card!")
  end

  def voucher_local_purchase_notification(to_address, valid_address, voucher, amount, image_url, item, expiration)
    @to_address = to_address
    @valid_address = valid_address
    @voucher = voucher.first
    @amount = amount
    @image_url = image_url || nil
    @item = item
    @expiration = Date.parse(expiration).strftime("%d/%m/%Y %I:%M%p")
    mail(to: @to_address, subject: "You successfully purchased a giftcard!")
  end
end
