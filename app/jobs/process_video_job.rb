# frozen_string_literal: true

# Background job for processing uploaded videos
# Extracts duration and generates thumbnail
class ProcessVideoJob < BaseSidekiqJob
  queue_as :default

  def perform(video_id)
    video = StudentVideo.find_by(id: video_id)
    return unless video
    return if video.file.blank?

    video_path = video.file.path
    return unless video_path && File.exist?(video_path)

    processor = VideoProcessor.new(video_path)
    result = processor.process

    # Update video with duration
    video.update_column(:duration_sec, result[:duration_sec]) if result[:duration_sec].positive?

    # Attach generated thumbnail (replace existing if any)
    if result[:thumbnail_path]
      begin
        # Remove old thumbnail if exists
        video.remove_thumbnail! if video.thumbnail.present?

        File.open(result[:thumbnail_path]) do |thumb_file|
          video.thumbnail = thumb_file
          video.save!
        end
      ensure
        # Clean up temp file
        FileUtils.rm_f(result[:thumbnail_path])
      end
    end

    Rails.logger.info "ProcessVideoJob: Processed video #{video_id}, duration: #{result[:duration_sec]}s"
  rescue VideoProcessor::ProcessingError => e
    Rails.logger.error "ProcessVideoJob: Processing error for video #{video_id}: #{e.message}"
  rescue StandardError => e
    Rails.logger.error "ProcessVideoJob: Unexpected error for video #{video_id}: #{e.message}"
    raise # Re-raise to trigger retry
  end
end
