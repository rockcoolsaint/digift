# Preview all emails at http://localhost:3000/rails/mailers/gift_card_mailer
class GiftCardMailerPreview < ActionMailer::Preview
  def voucher_purchase_notification
    # @message = "successful voucher purchase"
    GiftCardMailer.voucher_purchase_notification("rockcoolsaint@gmail.com", "https://blinksky.com/redeem/c13b967ac3824187a803b3903446c1c4")
  end
end
