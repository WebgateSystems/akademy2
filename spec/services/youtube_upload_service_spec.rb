# frozen_string_literal: true

require 'rails_helper'

RSpec.describe YoutubeUploadService do
  let(:file_path) { '/tmp/test_video.mp4' }
  let(:title) { 'Test Video Title' }
  let(:description) { 'Test video description' }
  let(:tags) { %w[Math Education] }
  let(:service) { described_class.new(file_path: file_path, title: title, description: description, tags: tags) }

  let(:youtube_service) { instance_double(Google::Apis::YoutubeV3::YouTubeService) }
  let(:uploaded_video) { double(id: 'test_video_id_123') }
  let(:oauth_client) { instance_double(Signet::OAuth2::Client) }

  before do
    allow(Google::Apis::YoutubeV3::YouTubeService).to receive(:new).and_return(youtube_service)
    allow(youtube_service).to receive(:authorization=)
    allow(youtube_service).to receive(:insert_video).and_return(uploaded_video)
    allow(Signet::OAuth2::Client).to receive(:new).and_return(oauth_client)

    # Mock Settings
    allow(Settings.services.youtube).to receive_messages(client_id: 'test_client_id',
                                                         client_secret: 'test_client_secret',
                                                         refresh_token: 'test_refresh_token')
  end

  describe '.call' do
    it 'creates instance and calls call method' do
      allow(described_class).to receive(:new).and_return(service)
      allow(service).to receive(:call).and_return(uploaded_video)

      result = described_class.call(
        file_path: file_path,
        title: title,
        description: description,
        tags: tags
      )

      expect(described_class).to have_received(:new).with(
        file_path: file_path,
        title: title,
        description: description,
        tags: tags
      )
      expect(result).to eq(uploaded_video)
    end
  end

  describe '#initialize' do
    it 'sets file_path, title, description, and tags' do
      expect(service.instance_variable_get(:@file_path)).to eq(file_path)
      expect(service.instance_variable_get(:@title)).to eq(title)
      expect(service.instance_variable_get(:@description)).to eq(description)
      expect(service.instance_variable_get(:@tags)).to eq(tags)
    end

    context 'when tags is not an array' do
      let(:tags) { 'single_tag' }

      it 'converts tags to array' do
        expect(service.instance_variable_get(:@tags)).to eq(['single_tag'])
      end
    end

    context 'when tags is nil' do
      let(:tags) { nil }

      it 'converts nil to empty array' do
        expect(service.instance_variable_get(:@tags)).to eq([])
      end
    end
  end

  describe '#call' do
    it 'returns uploaded video with id' do
      result = service.call

      expect(result).to eq(uploaded_video)
      expect(result.id).to eq('test_video_id_123')
    end

    it 'creates YouTube service with authorization' do
      service.call

      expect(Google::Apis::YoutubeV3::YouTubeService).to have_received(:new)
      expect(youtube_service).to have_received(:authorization=).with(oauth_client)
    end

    it 'calls insert_video with correct parameters' do
      service.call

      expect(youtube_service).to have_received(:insert_video) do |parts, resource, options|
        expect(parts).to eq('snippet,status')
        expect(resource).to be_a(Google::Apis::YoutubeV3::Video)
        expect(options[:upload_source]).to eq(file_path)
        expect(options[:content_type]).to eq('video/*')
      end
    end

    it 'creates video resource with correct snippet' do
      service.call

      expect(youtube_service).to have_received(:insert_video) do |_parts, resource, _options|
        expect(resource.snippet[:title]).to eq(title)
        expect(resource.snippet[:description]).to eq(description)
        expect(resource.snippet[:tags]).to eq(tags)
      end
    end

    it 'creates video resource with unlisted privacy status' do
      service.call

      expect(youtube_service).to have_received(:insert_video) do |_parts, resource, _options|
        expect(resource.status[:privacy_status]).to eq('unlisted')
      end
    end

    it 'creates OAuth client with correct settings' do
      service.call

      expect(Signet::OAuth2::Client).to have_received(:new).with(
        client_id: 'test_client_id',
        client_secret: 'test_client_secret',
        token_credential_uri: 'https://oauth2.googleapis.com/token',
        refresh_token: 'test_refresh_token',
        scope: 'https://www.googleapis.com/auth/youtube.upload'
      )
    end

    context 'when YouTube API raises an error' do
      before do
        allow(youtube_service).to receive(:insert_video).and_raise(Google::Apis::ClientError.new('API Error'))
      end

      it 'raises the error' do
        expect { service.call }.to raise_error(Google::Apis::ClientError, 'API Error')
      end
    end

    context 'when authorization fails' do
      before do
        allow(Signet::OAuth2::Client).to receive(:new).and_raise(Signet::AuthorizationError.new('Auth failed'))
      end

      it 'raises authorization error' do
        expect { service.call }.to raise_error(Signet::AuthorizationError)
      end
    end
  end

  describe 'constants' do
    it 'has YOUTUBE_SCOPE constant' do
      expect(described_class::YOUTUBE_SCOPE).to eq('https://www.googleapis.com/auth/youtube.upload')
    end

    it 'has PRIVACY_STATUS constant' do
      expect(described_class::PRIVACY_STATUS).to eq('unlisted')
    end
  end
end
