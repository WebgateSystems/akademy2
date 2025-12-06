# frozen_string_literal: true

class StudentVideoUploader < CarrierWave::Uploader::Base
  storage :file

  # Override storage directory
  def store_dir
    parts = model.id.to_s.scan(/.{1,2}/).first(2).join('/')
    "uploads/student_videos/#{parts}/#{model.id}"
  end

  # Generate unique filename
  def filename
    return if original_filename.blank?

    @filename ||= "#{SecureRandom.uuid}#{File.extname(original_filename).downcase}"
  end

  # Allowed video formats
  def extension_allowlist
    %w[mp4 webm mov avi mkv m4v]
  end

  # Max file size (100 MB by default, can be configured)
  def size_range
    0..100.megabytes
  end

  # Content type validation
  def content_type_allowlist
    %r{video/}
  end
end
