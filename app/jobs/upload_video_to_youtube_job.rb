# frozen_string_literal: true

class UploadVideoToYoutubeJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 5

  def perform(student_video_id)
    @video = StudentVideo.find_by(id: student_video_id)

    return log(:not_found, 'Video not found')            unless @video
    return log(:not_approved, 'Not approved')            unless @video.approved?
    return log(:already_uploaded, 'Already uploaded')    if @video.youtube_url.present?

    upload_to_youtube
  end

  private

  def upload_to_youtube
    result = execute_upload
    update_video_record(result)
    log(:success, "Uploaded to YouTube: #{result.id}")
  rescue Signet::AuthorizationError => e
    handle_auth_error(e)
  rescue Google::Apis::ServerError, Google::Apis::ClientError => e
    handle_api_error(e)
  rescue StandardError => e
    handle_unexpected_error(e)
  end

  # --- Small, single-purpose helpers ---

  def uploader
    YoutubeUploadService.new(
      file_path: @video.file.path,
      title: @video.title,
      description: @video.description,
      tags: [@video.subject_title, 'Akademy2.0']
    )
  end

  def execute_upload
    uploader.call
  end

  def update_video_record(result)
    @video.update!(
      youtube_url: "https://youtu.be/#{result.id}",
      youtube_id: result.id,
      youtube_uploaded_at: Time.current
    )
  end

  # --- Error handling ---

  def handle_auth_error(error)
    log(:auth_error, "Authorization failed: #{error.message}")
    raise
  end

  def handle_api_error(error)
    log(:api_error, "YouTube API error: #{error.message}")
    raise
  end

  def handle_unexpected_error(error)
    log(:unexpected, "Unexpected error: #{error.class} – #{error.message}")
    raise
  end

  def log(type, message)
    Rails.logger.info "[YouTubeUpload][#{type}] StudentVideo##{@video&.id} — #{message}"
  end
end
