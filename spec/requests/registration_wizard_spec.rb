require 'rails_helper'

RSpec.describe 'RegistrationWizards', type: :request do
  describe 'GET /step1' do
    it 'returns http success' do
      get '/registration_wizard/step1'
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /step2' do
    it 'returns http success' do
      get '/registration_wizard/step2'
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /step3' do
    it 'returns http success' do
      get '/registration_wizard/step3'
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /finish' do
    it 'returns http success' do
      get '/registration_wizard/finish'
      expect(response).to have_http_status(:success)
    end
  end
end
