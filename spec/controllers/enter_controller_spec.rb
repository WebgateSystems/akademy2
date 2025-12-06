# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EnterController, type: :controller do
  describe 'GET #index' do
    it 'returns http success' do
      get :index
      expect(response).to have_http_status(:success)
    end

    it 'renders enter layout' do
      get :index
      expect(response).to render_template(layout: 'enter')
    end
  end
end
