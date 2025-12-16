# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PagesController, type: :request do
  describe 'GET /privacy_policy' do
    it 'returns success' do
      get privacy_policy_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /accessibility' do
    it 'returns success' do
      get accessibility_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /license' do
    it 'returns success' do
      get license_path

      expect(response).to have_http_status(:ok)
    end
  end
end
