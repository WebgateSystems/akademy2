# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Store redirect (/get-app)', type: :request do
  let(:google_play_url) { Settings.stores.google_play.url }

  it 'redirects Android user agents to Google Play' do
    get get_app_path, headers: { 'User-Agent' => 'Mozilla/5.0 (Linux; Android 14; Pixel 7) AppleWebKit/537.36' }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to(google_play_url)
  end

  it 'renders fallback page for iOS when App Store URL is not configured' do
    get get_app_path, headers: { 'User-Agent' => 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)' }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Pobierz AKAdemy 2.0')
    expect(response.body).to include('Google Play')
    expect(response.body).to include('App Store (wkrótce)')
  end

  it 'redirects iOS user agents to App Store when configured' do
    app_store_url = 'https://apps.apple.com/app/id1234567890'
    allow(Settings).to receive_message_chain(:stores, :app_store, :url).and_return(app_store_url)

    get get_app_path, headers: { 'User-Agent' => 'Mozilla/5.0 (iPad; CPU OS 17_0 like Mac OS X)' }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to(app_store_url)
  end

  it 'supports platform override (android)' do
    get get_app_path(platform: 'android'),
        headers: { 'User-Agent' => 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)' }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to(google_play_url)
  end

  it 'shows fallback for unknown user agents' do
    get get_app_path, headers: { 'User-Agent' => 'curl/8.0.0' }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Pobierz AKAdemy 2.0')
  end
end
