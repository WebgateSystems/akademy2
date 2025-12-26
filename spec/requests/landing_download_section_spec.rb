# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Landing download section', type: :request do
  it 'renders "Pobierz na telefon" section with QR asset pointing to /get-app' do
    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Pobierz na telefon')
    expect(response.body).to include('https://akademy.edu.pl/get-app')
    expect(response.body).to match(%r{/assets/qr/get-app(?:-[0-9a-f]+)?\.svg})
  end
end
