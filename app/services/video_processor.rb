# frozen_string_literal: true

# Service for processing uploaded videos
# Extracts duration and generates thumbnail using FFmpeg
class VideoProcessor
  class ProcessingError < StandardError; end

  THUMBNAIL_TIME = 1 # seconds into video to capture thumbnail
  THUMBNAIL_MAX_DIMENSION = 640 # Max width or height

  def initialize(video_path)
    @video_path = video_path
    @movie = nil
  end

  # Process video and return metadata
  # @return [Hash] { duration_sec: Integer, thumbnail_path: String|nil }
  def process
    validate_ffmpeg!
    load_movie!

    {
      duration_sec: extract_duration,
      thumbnail_path: generate_thumbnail
    }
  end

  # Extract video duration in seconds
  # @return [Integer]
  def extract_duration
    load_movie! unless @movie
    @movie.duration.to_i
  rescue StandardError => e
    Rails.logger.error "VideoProcessor: Failed to extract duration: #{e.message}"
    0
  end

  # Generate thumbnail from video
  # @return [String, nil] Path to generated thumbnail or nil on failure
  def generate_thumbnail
    load_movie! unless @movie

    # Create temp file for thumbnail
    thumbnail_path = Rails.root.join('tmp', "thumb_#{SecureRandom.uuid}.jpg").to_s

    # Calculate time to capture (1 second in, or middle if video is very short)
    capture_time = [@movie.duration / 2, THUMBNAIL_TIME].min
    capture_time = 0 if capture_time.negative?

    # Calculate thumbnail size preserving aspect ratio
    resolution = calculate_thumbnail_resolution

    # Generate thumbnail using FFmpeg
    @movie.screenshot(
      thumbnail_path,
      seek_time: capture_time,
      resolution: resolution
    )

    thumbnail_path if File.exist?(thumbnail_path)
  rescue StandardError => e
    Rails.logger.error "VideoProcessor: Failed to generate thumbnail: #{e.message}"
    nil
  end

  # Get video metadata
  # @return [Hash]
  def metadata
    load_movie! unless @movie

    {
      duration: @movie.duration,
      bitrate: @movie.bitrate,
      size: @movie.size,
      video_codec: @movie.video_codec,
      audio_codec: @movie.audio_codec,
      resolution: @movie.resolution,
      width: @movie.width,
      height: @movie.height,
      frame_rate: @movie.frame_rate
    }
  rescue StandardError => e
    Rails.logger.error "VideoProcessor: Failed to get metadata: #{e.message}"
    {}
  end

  private

  # Calculate thumbnail resolution preserving original aspect ratio
  # @return [String] resolution in WxH format
  def calculate_thumbnail_resolution
    width = @movie.width.to_i
    height = @movie.height.to_i

    return "#{THUMBNAIL_MAX_DIMENSION}x#{THUMBNAIL_MAX_DIMENSION}" if width.zero? || height.zero?

    # Scale based on the larger dimension
    if width >= height
      # Horizontal or square video - scale by width
      new_width = [width, THUMBNAIL_MAX_DIMENSION].min
      new_height = (new_width.to_f / width * height).round
    else
      # Vertical video - scale by height
      new_height = [height, THUMBNAIL_MAX_DIMENSION].min
      new_width = (new_height.to_f / height * width).round
    end

    # Ensure dimensions are even (required by some codecs)
    new_width = (new_width / 2) * 2
    new_height = (new_height / 2) * 2

    "#{new_width}x#{new_height}"
  end

  def validate_ffmpeg!
    raise ProcessingError, 'FFmpeg is not installed or not in PATH' unless system('which ffmpeg > /dev/null 2>&1')

    return if system('which ffprobe > /dev/null 2>&1')

    raise ProcessingError, 'FFprobe is not installed or not in PATH'
  end

  def load_movie!
    raise ProcessingError, 'Video file not found' unless File.exist?(@video_path)

    @movie = FFMPEG::Movie.new(@video_path)

    raise ProcessingError, 'Invalid video file' unless @movie.valid?
  end
end
