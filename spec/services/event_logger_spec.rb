# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EventLogger, type: :service do
  let(:user) { create(:user) }
  let(:school) { create(:school) }
  let(:subject_model) { create(:subject, school: school) }
  let(:unit) { create(:unit, subject: subject_model) }
  let(:learning_module) { create(:learning_module, unit: unit) }
  let(:content) { create(:content, learning_module: learning_module) }

  describe '.log' do
    it 'creates an event with all attributes' do
      expect do
        described_class.log(
          event_type: 'test_event',
          user: user,
          school: school,
          data: { key: 'value' },
          client: 'test',
          occurred_at: Time.current
        )
      end.to change(Event, :count).by(1)

      event = Event.last
      expect(event.event_type).to eq('test_event')
      expect(event.user).to eq(user)
      expect(event.school).to eq(school)
      expect(event.data).to eq({ 'key' => 'value' })
      expect(event.client).to eq('test')
    end

    it 'uses user.school if school is not provided' do
      described_class.log(
        event_type: 'test_event',
        user: user,
        data: {}
      )

      event = Event.last
      expect(event.school).to eq(user.school)
    end

    it 'uses current time if occurred_at is not provided' do
      freeze_time = Time.current
      allow(Time).to receive(:current).and_return(freeze_time)

      described_class.log(
        event_type: 'test_event',
        user: user,
        data: {}
      )

      event = Event.last
      expect(event.occurred_at).to be_within(1.second).of(freeze_time)
    end

    it 'does not break application flow on error' do
      allow(Event).to receive(:create!).and_raise(StandardError.new('Database error'))

      expect do
        described_class.log(
          event_type: 'test_event',
          user: user,
          data: {}
        )
      end.not_to raise_error
    end

    it 'logs error to Rails.logger on failure' do
      allow(Event).to receive(:create!).and_raise(StandardError.new('Database error'))
      allow(Rails.logger).to receive(:error)

      described_class.log(
        event_type: 'test_event',
        user: user,
        data: {}
      )

      expect(Rails.logger).to have_received(:error).at_least(:once)
    end
  end

  describe '.log_api_request' do
    # rubocop:disable RSpec/MultipleExpectations
    it 'creates an api_request event' do
      described_class.log_api_request(
        method: 'GET',
        path: '/api/v1/schools',
        user: user,
        status: 200,
        params: { page: 1 },
        response_time: 45.5
      )

      event = Event.last
      expect(event.event_type).to eq('api_request')
      expect(event.user).to eq(user)
      expect(event.client).to eq('api')
      expect(event.data['method']).to eq('GET')
      expect(event.data['path']).to eq('/api/v1/schools')
      expect(event.data['status']).to eq(200)
      expect(event.data['params']).to eq({ 'page' => 1 })
      expect(event.data['response_time_ms']).to eq(45.5)
    end
    # rubocop:enable RSpec/MultipleExpectations

    it 'sanitizes sensitive params' do
      described_class.log_api_request(
        method: 'POST',
        path: '/api/v1/users',
        user: user,
        status: 201,
        params: {
          password: 'secret',
          password_confirmation: 'secret',
          token: 'abc123',
          access_token: 'xyz789',
          refresh_token: 'refresh123',
          safe_param: 'value'
        }
      )

      event = Event.last
      expect(event.data['params']).not_to have_key('password')
      expect(event.data['params']).not_to have_key('password_confirmation')
      expect(event.data['params']).not_to have_key('token')
      expect(event.data['params']).not_to have_key('access_token')
      expect(event.data['params']).not_to have_key('refresh_token')
      expect(event.data['params']['safe_param']).to eq('value')
    end
  end

  describe '.log_login' do
    it 'creates a user_login event' do
      described_class.log_login(user: user, client: 'web')

      event = Event.last
      expect(event.event_type).to eq('user_login')
      expect(event.user).to eq(user)
      expect(event.school).to eq(user.school)
      expect(event.data['login_method']).to eq('web')
      expect(event.client).to eq('web')
    end

    it 'defaults client to web' do
      described_class.log_login(user: user)

      event = Event.last
      expect(event.client).to eq('web')
    end
  end

  describe '.log_logout' do
    it 'creates a user_logout event' do
      described_class.log_logout(user: user, client: 'api')

      event = Event.last
      expect(event.event_type).to eq('user_logout')
      expect(event.user).to eq(user)
      expect(event.school).to eq(user.school)
      expect(event.client).to eq('api')
    end
  end

  describe '.log_video_view' do
    it 'creates a video_view event' do
      described_class.log_video_view(
        content: content,
        user: user,
        duration: 120,
        progress: 75
      )

      event = Event.last
      expect(event.event_type).to eq('video_view')
      expect(event.user).to eq(user)
      expect(event.data['content_id']).to eq(content.id)
      expect(event.data['content_title']).to eq(content.title)
      expect(event.data['learning_module_id']).to eq(content.learning_module_id)
      expect(event.data['duration']).to eq(120)
      expect(event.data['progress']).to eq(75)
    end

    it 'allows optional duration and progress' do
      described_class.log_video_view(
        content: content,
        user: user
      )

      event = Event.last
      expect(event.data['duration']).to be_nil
      expect(event.data['progress']).to be_nil
    end
  end

  describe '.log_quiz_start' do
    it 'creates a quiz_start event' do
      described_class.log_quiz_start(quiz: learning_module, user: user)

      event = Event.last
      expect(event.event_type).to eq('quiz_start')
      expect(event.user).to eq(user)
      expect(event.data['quiz_id']).to eq(learning_module.id)
      expect(event.data['quiz_title']).to eq(learning_module.title)
      expect(event.data['learning_module_id']).to eq(learning_module.id)
    end
  end

  describe '.log_quiz_complete' do
    let(:quiz_result) do
      create(:quiz_result, user: user, learning_module: learning_module, score: 85, passed: true)
    end

    it 'creates a quiz_complete event' do
      described_class.log_quiz_complete(quiz_result: quiz_result, user: user)

      event = Event.last
      expect(event.event_type).to eq('quiz_complete')
      expect(event.user).to eq(user)
      expect(event.data['quiz_result_id']).to eq(quiz_result.id)
      expect(event.data['quiz_id']).to eq(learning_module.id)
      expect(event.data['score']).to eq(85)
      expect(event.data['passed']).to be(true)
    end
  end

  describe '.log_content_access' do
    it 'creates a content_view event by default' do
      described_class.log_content_access(content: content, user: user)

      event = Event.last
      expect(event.event_type).to eq('content_view')
      expect(event.data['content_id']).to eq(content.id)
      expect(event.data['content_type']).to eq(content.content_type)
    end

    it 'allows custom action' do
      described_class.log_content_access(content: content, user: user, action: 'download')

      event = Event.last
      expect(event.event_type).to eq('content_download')
    end
  end
end
