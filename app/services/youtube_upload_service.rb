# frozen_string_literal: true

require 'google/apis/youtube_v3'
require 'googleauth'

class YoutubeUploadService
  # Needs to allow both upload + management operations (e.g. delete).
  # IMPORTANT: if you change scopes, you must generate a new refresh token with those scopes.
  YOUTUBE_SCOPE = 'https://www.googleapis.com/auth/youtube.force-ssl'

  def self.call(**args)
    new(**args).call
  end

  def initialize(file_path:, title:, description:, tags: [])
    @file_path = file_path
    @title = title
    @description = description
    @tags = Array(tags)
  end

  def call
    youtube.insert_video(
      video_parts,
      video_resource,
      upload_source: file_path,
      content_type: 'video/*'
    )
  end

  private

  attr_reader :file_path, :title, :description, :tags

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

  def video_parts
    'snippet,status'
  end

  def video_resource
    Google::Apis::YoutubeV3::Video.new(
      snippet: snippet,
      status: status
    )
  end

  def snippet
    {
      title: title,
      description: description,
      tags: tags
    }
  end

  def status
    {
      privacy_status: Settings.services.youtube.privacy_status
    }
  end
end
