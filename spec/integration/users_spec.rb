require 'swagger_helper'

describe 'Users API' do

  path '/auth/register/business' do

    post 'Creates a business user' do
      tags 'Users'
      consumes 'application/json'
      parameter name: :user, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string, example: "example@email.com" },
          password: { type: :string, example: "123456" },
          password_confirmation: { type: :string, example: "123456" },
          first_name: { type: :string, example: "Seun" },
          last_name: { type: :string, example: "Ezike" },
          business_name: { type: :string, example: "Digift Nigeria Ltd" },
          industry: { type: :string, example: "tech" },
          country: { type: :string, example: "Nigeria" },
          staff_strength: { type: :string, example: "1-5" },
          role: { type: :string, example: "owner" },
          website: { type: :string, example: "digiftng.com" },
          registration_status: { type: :string }
        },
        required: [ 'email', 'password', 'password_confirmation', 'business_name', 'country' ]
      }

      response '200', 'user created' do
        let(:user) { { email: 'test_email@email.com', password: '123456', password_confirmation: '123456', business_name: 'digiftng', country: 'Nigeria' } }
        run_test!
      end

      response '422', 'invalid request' do
        let(:user) { { email: 'test_email@email.com', password: '123456', business_name: 'digiftng', country: 'Nigeria' } }
        run_test!
      end
    end
  end

  path '/auth/register/personal' do

    post 'Creates a personal user' do
      tags 'Users'
      consumes 'application/json'
      parameter name: :user, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string, example: "example@email.com" },
          password: { type: :string, example: "123456" },
          password_confirmation: { type: :string, example: "123456" },
          first_name: { type: :string, example: "Seun" },
          last_name: { type: :string, example: "Ezike" }
        },
        required: [ 'email', 'password', 'password_confirmation' ]
      }

      response '200', 'user created' do
        let(:user) { { email: 'test_email@email.com', password: '123456', password_confirmation: '123456' } }
        run_test!
      end

      response '422', 'invalid request' do
        let(:user) { { email: 'test_email@email.com', password: '123456' } }
        run_test!
      end
    end
  end

  path '/auth/sign_in' do
    post 'Sign in user' do
      tags 'Users'
      consumes 'application/json'
      parameter name: :user, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string, example: "example@email.com" },
          password: { type: :string, example: "123456" }
        },
        required: [ 'email', 'password'],
      }

      response '200', 'user logged in' do
        let(:user) { { email: 'test_email@email.com', password: '123456' } }
        run_test!
      end

      response '401', 'user logged in failed' do
        let(:user) { { email: 'test_email@email.com' } }
        run_test!
      end

      response '401', 'user logged in failed' do
        let(:user) { { password: '123456' } }
        run_test!
      end
    end
  end

  path '/auth/sign_out' do
    post 'Sign out user' do
      tags 'Users'
      consumes 'application/json'
      parameter name: :user, in: :header, schema: {
        type: :object,
        properties: {
          'access-token': { type: :string, example: "XxXSrAP8AxiWKEzR_Z2ijA" },
          client: { type: :string, example: "H3EKqopxAGZbHYer2UDi_Q" },
          uid: { type: :string, example: "currently_logged_in_user@email.com" }
        },
        required: [ 'access-token', 'client', 'uid']
      }

      response '200', 'user logged out' do
        run_test!
      end
    end
  end

  path '/auth/me' do
    get 'Current signed in user' do
      tags 'Users'
      produces 'application/json'
      parameter name: :'access-token', in: :header, type: :string, example: "XxXSrAP8AxiWKEzR_Z2ijA"
      parameter name: :client, in: :header, type: :string, example: "H3EKqopxAGZbHYer2UDi_Q"
      parameter name: :uid, in: :header, type: :string, example: "currently_logged_in_user@email.com"

      response '200', 'Currently signed in user' do
        let(:'access-token') {'XxXSrAP8AxiWKEzR_Z2ijA'}
        let(:client) {'H3EKqopxAGZbHYer2UDi_Q'}
        let(:uid) {'currently_logged_in_user@email.com'}
        run_test!
      end
    end
  end
end