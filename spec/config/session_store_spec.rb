# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Session store configuration' do
  it 'uses CookieStore when Settings.redis_url is blank, Redis store when present' do
    # Session store is chosen at boot based on Settings.redis_url (see config/application.rb).
    store = Rails.application.config.session_store
    if Settings.redis_url.presence
      expect(store).not_to eq(ActionDispatch::Session::CookieStore)
    else
      expect(store).to eq(ActionDispatch::Session::CookieStore)
    end
  end
end
