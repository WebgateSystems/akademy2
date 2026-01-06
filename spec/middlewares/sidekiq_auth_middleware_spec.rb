# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SidekiqAuthMiddleware do
  subject(:response) { middleware.call(env) }

  let(:app) { ->(_env) { [200, { 'Content-Type' => 'text/plain' }, ['OK']] } }
  let(:middleware) { described_class.new(app) }
  let(:session) { {} }
  let(:env) do
    {
      'rack.session' => session
    }
  end

  let(:user) { instance_double(User, admin?: false, manager?: false) }
  let(:token) { 'jwt-token' }
  let(:decoded_token) do
    {
      user_id: 1,
      exp: Time.now.to_i + 1.hour.to_i
    }
  end

  before do
    allow(User).to receive(:find_by).with(id: decoded_token[:user_id]).and_return(user)
  end

  describe '#call' do
    context 'when token is missing' do
      it 'redirects to admin sign in' do
        status, headers, _body = response

        expect(status).to eq(302)
        expect(headers['Location']).to eq('/admin/sign_in')
      end
    end

    context 'when token is invalid' do
      before do
        session[:admin_id] = token
        allow(::Jwt::TokenService).to receive(:decode).and_raise(JWT::DecodeError)
      end

      it 'redirects to admin sign in' do
        status, headers, _body = response

        expect(status).to eq(302)
        expect(headers['Location']).to eq('/admin/sign_in')
      end
    end

    context 'when token is expired' do
      let(:decoded_token) do
        {
          user_id: 1,
          exp: Time.now.to_i - 10
        }
      end

      before do
        session[:admin_id] = token
        allow(::Jwt::TokenService).to receive(:decode).and_return(decoded_token)
      end

      it 'redirects to admin sign in' do
        status, headers, _body = response

        expect(status).to eq(302)
        expect(headers['Location']).to eq('/admin/sign_in')
      end
    end

    context 'when user is not admin or manager' do
      before do
        session[:admin_id] = token
        allow(::Jwt::TokenService).to receive(:decode).and_return(decoded_token)
        allow(user).to receive_messages(admin?: false, manager?: false)
      end

      it 'redirects to admin sign in' do
        status, headers, _body = response

        expect(status).to eq(302)
        expect(headers['Location']).to eq('/admin/sign_in')
      end
    end

    context 'when user is admin' do
      before do
        session[:admin_id] = token
        allow(::Jwt::TokenService).to receive(:decode).and_return(decoded_token)
        allow(user).to receive(:admin?).and_return(true)
      end

      it 'passes request to the app' do
        status, _headers, body = response

        expect(status).to eq(200)
        expect(body).to eq(['OK'])
      end
    end

    context 'when user is manager' do
      before do
        session[:admin_id] = token
        allow(::Jwt::TokenService).to receive(:decode).and_return(decoded_token)
        allow(user).to receive(:manager?).and_return(true)
      end

      it 'passes request to the app' do
        status, _headers, body = response

        expect(status).to eq(200)
        expect(body).to eq(['OK'])
      end
    end
  end
end
