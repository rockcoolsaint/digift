class UtilityMailer < ApplicationMailer
  def utility_renewal_cabletv_notification(to_address, service_type)
    @to = to_address
    @service_type = service_type
    mail(to: @to, subject: "You successfully renewed your #{service_type} subscription!")
  end

  def utility_change_cabletv_notification(to_address, service_type)
    @to = to_address
    @service_type = service_type
    mail(to: @to, subject: "You successfully changed your #{service_type} subscription!")
  end

  def utility_pay_electric_notification(to_address, service_type, data)
    @to = to_address
    @service_type = service_type
    @token_code = nil
    @token_amount = nil
    @amount_of_power = nil
    @token_code = data["data"]["tokenCode"] unless data["data"]["tokenCode"].blank?
    @token_amount = data["data"]["tokenAmount"] unless data["data"]["tokenAmount"].blank?
    @amount_of_power = data["data"]["amountOfPower"] unless data["data"]["amountOfPower"].blank?
    mail(to: @to, subject: "You successfully recharged your #{service_type} subscription!")
  end

  def utility_epin_purchase_notification(to_address, service_type, data)

    @to = to_address
    @service_type = service_type
    @pins = data.try(:[],"data").try(:[],"pins")
    @message = data.try(:[],"data").try(:[],"provider_message")
    mail(to: @to, subject: "You successfully purchased your #{service_type} e-pin!")
  end
end
