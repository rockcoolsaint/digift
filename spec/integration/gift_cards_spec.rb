require 'swagger_helper'

describe 'Giftcards API' do

  path '/api/v1/available-giftcards' do

    post 'Fetches a list of available giftcards' do
      tags 'Giftcards'
      consumes 'application/json'

      response '200', 'user giftcards' do
        run_test!
      end
    end
  end

  path '/api/v1/gift-cards/send' do

    post 'Send a giftcard request' do
      tags 'Giftcards'
      consumes 'application/json'
      parameter name: :params, in: :body, schema: {
        type: :object,
        properties: {
          data: {
            type: :object,
            properties: {
              action: { type: :string, example: "order" },
              apiKey: { type: :string, example: "1f8c60995982dcc733c707ca36a2472b" },
              from: { type: :string, example: '0787764444566' },
              sender: { type: :string, example: "A Business Name" },
              postal: { type: :string, example: "1001020" },
              msg: { type: :string, example: "Thanks for doing business with us" },
              card: {
                type: :object,
                properties: {
                  code: { type: :string, example: "62" },
                  amount: { type: :integer, example: 100 },
                  dest: { type: :string, example: "beneficiary@receiver.com" }, # this could be a number or email
                  order_id: { type: :string, example: "2d931510-d99f-494a-8c67-87feb05e1594" }
                }
              }
            }
          }
        },
        required: [ 'data' ]
      }

      response '200', 'giftcard sent' do
        let(:data) { {
          "data":{
            "action": "order",
            "apiKey": "96f6c524fec1579a595c51ae2e176491",
            "from": "17705551234",
            "sender":"A Business Name",
            "postal": "30005",
            "msg": "A message from the Business",
            "card": {
              "code": "62",
              "amount": 100,
              "order_id": "2d931510-d99f-494a-8c67-87feb05e1594"
            }
          }
        } }
        run_test!
      end
    end
  end

  path '/api/v1/gift-cards/send_retail' do

    post 'Send a giftcard request' do
      tags 'Giftcards'
      consumes 'application/json'
      parameter name: :params, in: :body, schema: {
        type: :object,
        properties: {
          data: {
            type: :object,
            properties: {
              action: { type: :string, example: "order" },
              from: { type: :string, example: '0787764444566' },
              sender: { type: :string, example: "DigiftNG" },
              postal: { type: :string, example: "1001020" },
              msg: { type: :string, example: "Thanks for doing business with us" },
              card: {
                type: :object,
                properties: {
                  code: { type: :string, example: "62" },
                  amount: { type: :integer, example: 100 },
                  dest: { type: :string, example: "beneficiary@receiver.com" }, # this could be a number or email
                  order_id: { type: :string, example: "2d931510-d99f-494a-8c67-87feb05e1594" }
                }
              }
            }
          }
        },
        required: [ 'data' ]
      }

      response '200', 'giftcard sent' do
        let(:data) { {
          "data":{
            "action": "order",
            "from": "17705551234",
            "sender":"DigiftNG",
            "postal": "30005",
            "msg": "A message from the Business",
            "card": {
              "code": "62",
              "amount": 100,
              "order_id": "2d931510-d99f-494a-8c67-87feb05e1594"
            }
          }
        } }
        run_test!
      end
    end
  end
end