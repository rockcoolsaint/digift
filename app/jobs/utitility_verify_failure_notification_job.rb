class UtitilityVerifyFailureNotificationJob < ApplicationJob
  queue_as :default

  def perform(user, data, errMessage="Oops! Something went wrong", transaction)
    return unless ENV['USER_DROPOFF_SLACK_WEBHOOK_URL'].present?
    name = "#{user.profiles.first.first_name} #{user.profiles.first.last_name}"
    payload = {
      text: "Transaction failed",
      "blocks": [
        {
          "type": "header",
          "text": {
            "type": "plain_text",
            "text": "Verification failure"
          }
        },
        {
          "type": "section",
          "fields": [
            {
              "type": "mrkdwn",
              "text": "*User:*\n#{name}"
            },
            {
              "type": "mrkdwn",
              "text": "*Mobile:*\n#{user.email}"
            },
            {
              "type": "mrkdwn",
              "text": "*Mobile:*\n#{user.profiles.first.phone_number}"
            }
          ]
        },
        {
          "type": "section",
          "fields": [
            {
              "type": "mrkdwn",
              "text": "*Data:*\n#{data}"
            },
            {
              "type": "mrkdwn",
              "text": "*Transsaction:*\n#{transaction.nil? ? {} : transaction}"
            }
          ]
        },
        {
          "type": "section",
          "fields": [
            {
              "type": "mrkdwn",
              "text": "*Error Message:*\n#{errMessage}"
            }
          ]
        }
      ]
    }
    begin
      RestClient.post(ENV['USER_DROPOFF_SLACK_WEBHOOK_URL'],
        payload.to_json,
        {content_type: :json, accept: :json}
      )
    rescue => exception
      raise(ExceptionHandler::RegularError, errMessage)
    end
   
  end
end
