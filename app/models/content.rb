class Content < ApplicationRecord
  belongs_to :learning_module
  has_many :likes, class_name: 'ContentLike', dependent: :destroy
  has_many :liking_users, through: :likes, source: :user

  mount_uploader :file, BaseUuidUploader
  mount_uploader :poster, BaseUuidUploader
  mount_uploader :subtitles, BaseUuidUploader

  before_save :update_file_metadata, if: :file_changed?

  # Check if content is likeable (video or infographic, not quiz)
  def likeable?
    %w[video infographic].include?(content_type)
  end

  def liked_by?(user)
    return false unless user

    likes.exists?(user_id: user.id)
  end

  def toggle_like!(user)
    return false unless likeable?

    like = likes.find_by(user_id: user.id)
    liked = if like
              like.destroy
              false
            else
              likes.create!(user: user)
              true
            end

    reload # Get updated likes_count from counter_cache

    # Log to activity log
    EventLogger.log_content_like(content: self, user: user, liked: liked) if defined?(EventLogger)
    liked
  end

  # Video format mapping for common extensions
  VIDEO_FORMATS = {
    'mp4' => 'video/mp4',
    'webm' => 'video/webm',
    'mov' => 'video/quicktime',
    'avi' => 'video/x-msvideo',
    'mkv' => 'video/x-matroska',
    'm4v' => 'video/x-m4v'
  }.freeze

  private

  def file_changed?
    file.present? && (new_record? || file_previously_changed? || will_save_change_to_file?)
  end

  def update_file_metadata
    return unless file.present? && file.file.present?

    update_file_hash
    update_file_format
  end

  def update_file_hash
    file_path = file.file.path || file.file.file
    return unless file_path && File.exist?(file_path)

    self.file_hash = Digest::SHA256.file(file_path).hexdigest
  rescue StandardError => e
    Rails.logger.error("Failed to generate file hash for content #{id}: #{e.message}")
    nil
  end

  MIME_TYPES = {
    'pdf' => 'application/pdf',
    'jpg' => 'image/jpeg',
    'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'svg' => 'image/svg+xml'
  }.freeze

  def update_file_format
    return if file.file.blank?

    extension = File.extname(file.file.filename.to_s).delete('.').downcase
    self.file_format = VIDEO_FORMATS[extension] || MIME_TYPES[extension] || 'application/octet-stream'
  end
end
