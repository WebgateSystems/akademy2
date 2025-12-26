# frozen_string_literal: true

require 'google/apis/youtube_v3'
require 'googleauth'

class YoutubeDeleteService
  YOUTUBE_SCOPE = 'https://www.googleapis.com/auth/youtube.upload'

  def initialize(youtube_id:)
    @youtube_id = youtube_id
  end

  def call
    youtube.delete_video(youtube_id)
    :deleted
  rescue Google::Apis::ClientError => e
    # Already deleted manually from YouTube Studio / by channel admin
    return :already_deleted if not_found?(e)

    raise
  end

  private

  attr_reader :youtube_id

  def youtube
    @youtube ||= Google::Apis::YoutubeV3::YouTubeService.new.tap do |service|
      service.authorization = authorization
    end
  end

  def authorization
    Signet::OAuth2::Client.new(
      client_id: Settings.services.youtube.client_id,
      client_secret: Settings.services.youtube.client_secret,
      token_credential_uri: token_uri,
      refresh_token: Settings.services.youtube.refresh_token,
      scope: YOUTUBE_SCOPE
    )
  end

  def token_uri
    'https://oauth2.googleapis.com/token'
  end

  def not_found?(error)
    (error.respond_to?(:status_code) && error.status_code.to_i == 404) ||
      error.message&.match?(/notFound|404/i)
  end
end
