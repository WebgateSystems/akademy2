# frozen_string_literal: true

require 'rails_helper'

RSpec.describe YoutubeDeleteService do
  let(:youtube_id) { 'yt_video_123' }
  let(:service) { described_class.new(youtube_id: youtube_id) }

  let(:youtube_service) { instance_double(Google::Apis::YoutubeV3::YouTubeService) }
  let(:oauth_client) { instance_double(Signet::OAuth2::Client) }

  before do
    allow(Google::Apis::YoutubeV3::YouTubeService).to receive(:new).and_return(youtube_service)
    allow(youtube_service).to receive(:authorization=)
    allow(Signet::OAuth2::Client).to receive(:new).and_return(oauth_client)

    allow(Settings.services.youtube).to receive_messages(client_id: 'test_client_id',
                                                         client_secret: 'test_client_secret',
                                                         refresh_token: 'test_refresh_token')
  end

  it 'deletes the video and returns :deleted' do
    allow(youtube_service).to receive(:delete_video).with(youtube_id).and_return(true)
    expect(service.call).to eq(:deleted)
  end

  it 'returns :already_deleted when YouTube responds with 404' do
    error = Google::Apis::ClientError.new('notFound')
    allow(error).to receive(:status_code).and_return(404)
    allow(youtube_service).to receive(:delete_video).with(youtube_id).and_raise(error)

    expect(service.call).to eq(:already_deleted)
  end
end
