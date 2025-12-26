# frozen_string_literal: true

class DeleteYoutubeVideoJob < BaseSidekiqJob
  sidekiq_options queue: :internal, retry: 5

  # @param student_video_id [String] just for logging/debug (record may already be deleted)
  # @param youtube_id [String] YouTube video id to delete
  def perform(student_video_id, youtube_id)
    result = YoutubeDeleteService.new(youtube_id: youtube_id).call

    Rails.logger.info "[YouTubeDelete][#{result}] StudentVideo##{student_video_id} youtube_id=#{youtube_id}"
  rescue StandardError => e
    Rails.logger.error(
      "[YouTubeDelete][fail] StudentVideo##{student_video_id} youtube_id=#{youtube_id} — " \
      "#{e.class}: #{e.message}"
    )
    raise
  end
end
