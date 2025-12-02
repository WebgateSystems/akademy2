# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::Sessions::CreateSession do
  let(:user) { create(:user, email: 'teacher@example.com', password: 'Password1', password_confirmation: 'Password1') }

  before do
    user # ensure user is created before tests
    allow(Jwt::TokenService).to receive(:encode).and_return('jwt-token')
    allow(EventLogger).to receive(:log_login)
  end

  def call_interactor(params)
    described_class.call(params: params)
  end

  it 'creates session using email strategy' do
    result = call_interactor(user: { email: user.email, password: 'Password1' })

    expect(result).to be_success
    expect(result.form).to eq(user)
    expect(result.access_token).to eq('jwt-token')
    expect(EventLogger).to have_received(:log_login).with(user: user, client: 'api')
  end

  it 'fails when credentials missing' do
    result = call_interactor({})

    expect(result).to be_failure
    expect(result.message).to include('Missing login fields')
  end

  it 'fails when user not found' do
    result = call_interactor(user: { email: 'missing@example.com', password: 'Password1' })

    expect(result).to be_failure
    expect(result.message).to include('User does not exist')
  end

  it 'fails when password invalid' do
    result = call_interactor(user: { email: user.email, password: 'wrong' })

    expect(result).to be_failure
    expect(result.message).to include('Invalid password or PIN')
  end
end
