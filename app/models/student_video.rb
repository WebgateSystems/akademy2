# frozen_string_literal: true

class StudentVideo < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :subject
  belongs_to :school, optional: true
  belongs_to :moderated_by, class_name: 'User', optional: true

  has_many :likes, class_name: 'StudentVideoLike', dependent: :destroy
  has_many :liking_users, through: :likes, source: :user

  # CarrierWave uploader
  mount_uploader :file, StudentVideoUploader
  mount_uploader :thumbnail, StudentVideoThumbnailUploader

  # Elasticsearch via Searchkick
  searchkick word_start: %i[title description author_name author_first_name author_last_name],
             searchable: %i[title description author_name author_first_name author_last_name school_name subject_title
                            author_class_name],
             filterable: %i[status subject_id school_id user_id],
             callbacks: :async

  # Statuses
  STATUSES = %w[pending approved rejected].freeze

  # Validations
  validates :title, presence: true, length: { maximum: 200 }
  validates :description, length: { maximum: 2000 }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :file, presence: true

  # Scopes
  scope :pending, -> { where(status: 'pending') }
  scope :approved, -> { where(status: 'approved') }
  scope :rejected, -> { where(status: 'rejected') }
  scope :by_subject, ->(subject_id) { where(subject_id: subject_id) if subject_id.present? }
  scope :by_school, ->(school_id) { where(school_id: school_id) if school_id.present? }
  scope :newest_first, -> { order(created_at: :desc) }

  # Callbacks
  after_destroy :remove_file_from_disk
  after_commit :process_video, on: :create

  # Instance methods
  def pending?
    status == 'pending'
  end

  def approved?
    status == 'approved'
  end

  def rejected?
    status == 'rejected'
  end

  # Accessor aliases for clarity (moderated_by/moderated_at work for both approve and reject)
  def approved_by
    moderated_by
  end

  def approved_at
    moderated_at
  end

  def rejected_by
    moderated_by
  end

  def rejected_at
    moderated_at
  end

  def can_be_deleted_by?(current_user)
    return false unless pending?

    user_id == current_user.id
  end

  def approve!(moderator)
    update!(
      status: 'approved',
      moderated_by: moderator,
      moderated_at: Time.current
    )

    # Log to activity log
    EventLogger.log_student_video_approve(video: self, moderator: moderator)

    # Send notification to student
    NotificationService.create_student_video_approved(video: self, moderator: moderator)

    # Enqueue YouTube upload job
    UploadVideoToYoutubeJob.perform_later(id) if youtube_url.blank?
  end

  def reject!(moderator, reason = nil)
    update!(
      status: 'rejected',
      moderated_by: moderator,
      moderated_at: Time.current,
      rejection_reason: reason
    )

    # Log to activity log
    EventLogger.log_student_video_reject(video: self, moderator: moderator, reason: reason)

    # Send notification to student
    NotificationService.create_student_video_rejected(video: self, moderator: moderator, reason: reason)
  end

  def liked_by?(user)
    likes.exists?(user_id: user.id)
  end

  def toggle_like!(user)
    like = likes.find_by(user_id: user.id)
    liked = if like
              like.destroy
              # counter_cache automatically decrements likes_count
              false
            else
              likes.create!(user: user)
              # counter_cache automatically increments likes_count
              true
            end

    # Reload to get updated likes_count from counter_cache
    reload

    # Log to activity log
    EventLogger.log_student_video_like(video: self, user: user, liked: liked)
    liked
  end

  def author_name
    user&.full_name || 'Unknown'
  end

  def author_first_name
    user&.first_name
  end

  def author_last_name
    user&.last_name
  end

  def author_class_name
    # Get the student's current class name
    user&.school_classes&.first&.name
  end

  def school_name
    school&.name
  end

  def subject_title
    subject&.title
  end

  # Searchkick data for indexing
  def search_data
    {
      title: title,
      description: description,
      author_name: author_name,
      author_first_name: author_first_name,
      author_last_name: author_last_name,
      author_class_name: author_class_name,
      school_name: school_name,
      subject_title: subject_title,
      status: status,
      subject_id: subject_id,
      school_id: school_id,
      user_id: user_id,
      likes_count: likes_count,
      created_at: created_at
    }
  end

  # Only index approved videos in search (pending/rejected stay in DB but not searchable)
  def should_index?
    approved?
  end

  private

  def process_video
    # Enqueue background job to extract duration and generate thumbnail
    ProcessVideoJob.perform_later(id)
  end

  def remove_file_from_disk
    remove_file!
    remove_thumbnail!
  rescue StandardError => e
    Rails.logger.error "Failed to remove video file: #{e.message}"
  end
end
