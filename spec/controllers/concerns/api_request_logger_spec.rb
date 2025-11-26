# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiRequestLogger, type: :request do
  include ApplicationTestHelper

  let(:admin_role) { Role.find_or_create_by!(key: 'admin') { |r| r.name = 'Admin' } }
  let(:admin_user) do
    user = create(:user)
    UserRole.find_or_create_by!(user: user, role: admin_role) { |ur| ur.school = user.school }
    user
  end
  let(:auth_token) { "Bearer #{generate_token(admin_user)}" }

  describe 'API request logging' do
    # rubocop:disable RSpec/MultipleExpectations
    it 'logs successful API requests' do
      expect do
        get '/api/v1/schools', headers: { 'Authorization' => auth_token }
      end.to change(Event, :count).by(1)

      event = Event.last
      expect(event.event_type).to eq('api_request')
      expect(event.user).to eq(admin_user)
      expect(event.data['method']).to eq('GET')
      expect(event.data['path']).to eq('/api/v1/schools')
      expect(event.data['status']).to eq(200)
      expect(event.client).to eq('api')
    end
    # rubocop:enable RSpec/MultipleExpectations

    it 'includes response time in event data' do
      get '/api/v1/schools', headers: { 'Authorization' => auth_token }

      event = Event.last
      expect(event.data['response_time_ms']).to be_a(Numeric)
      expect(event.data['response_time_ms']).to be >= 0
    end

    it 'does not log requests when user is not authenticated' do
      expect do
        get '/api/v1/schools', headers: { 'Authorization' => nil }
      end.not_to change(Event, :count)
    end
  end
end
