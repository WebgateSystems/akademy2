# frozen_string_literal: true

class DeleteYoutubeVideoJob < BaseSidekiqJob
  sidekiq_options queue: :internal, retry: 5

  # @param student_video_id [String] just for logging/debug (record may already be deleted)
  # @param youtube_id [String] YouTube video id to delete
  def perform(student_video_id, youtube_id)
    result = YoutubeDeleteService.new(youtube_id: youtube_id).call

    log_info("[#{result}] StudentVideo##{student_video_id} youtube_id=#{youtube_id}")
  rescue Google::Apis::ClientError => e
    handle_client_error!(e, student_video_id, youtube_id)
  rescue StandardError => e
    log_error(
      "[fail] StudentVideo##{student_video_id} youtube_id=#{youtube_id} — #{e.class}: #{e.message}"
    )
    raise
  end

  private

  def handle_client_error!(error, student_video_id, youtube_id)
    # Permanent misconfiguration: token does not have required OAuth scopes.
    # Don't spam retries; log and stop.
    if insufficient_scopes?(error)
      log_error(
        "[insufficient_scopes] StudentVideo##{student_video_id} youtube_id=#{youtube_id} — #{error.message}"
      )
      return
    end

    raise error
  end

  def insufficient_scopes?(error)
    error.message&.match?(/insufficient authentication scopes/i)
  end

  def log_info(message)
    Rails.logger.info "[YouTubeDelete] #{message}"
  end

  def log_error(message)
    Rails.logger.error "[YouTubeDelete] #{message}"
  end
end
