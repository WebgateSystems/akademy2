# frozen_string_literal: true

class UploadVideoToYoutubeJob < ApplicationJob
  queue_as :default

  # Retry with exponential backoff on YouTube API errors
  retry_on StandardError, wait: :polynomially_longer, attempts: 5

  def perform(student_video_id)
    student_video = StudentVideo.find_by(id: student_video_id)
    return unless student_video
    return unless student_video.approved?
    return if student_video.youtube_url.present?

    # TODO: Implement YouTube API upload
    # This requires:
    # 1. Google API credentials (OAuth2 or service account)
    # 2. YouTube Data API v3
    # 3. Channel ID to upload to
    #
    # Example implementation:
    # youtube_service = YoutubeUploadService.new
    # result = youtube_service.upload(
    #   file_path: student_video.file.path,
    #   title: student_video.title,
    #   description: student_video.description,
    #   tags: [student_video.subject_title, 'Akademy2.0']
    # )
    #
    # student_video.update!(
    #   youtube_url: result[:url],
    #   youtube_id: result[:video_id],
    #   youtube_uploaded_at: Time.current
    # )

    Rails.logger.info "[YouTubeUpload] Job for StudentVideo##{student_video_id} - " \
                      'YouTube upload not yet implemented'
  end
end
