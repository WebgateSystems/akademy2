# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
class EventLogger
  # rubocop:disable Metrics/ParameterLists
  def self.log(event_type:, user: nil, school: nil, data: {}, client: nil, occurred_at: nil)
    occurred_at ||= Time.current

    Event.create!(
      event_type: event_type.to_s,
      user: user,
      school: school || user&.school,
      data: data,
      client: client,
      occurred_at: occurred_at
    )
  rescue StandardError => e
    # Log error but don't break the application flow
    Rails.logger.error("Failed to log event: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
  end
  # rubocop:enable Metrics/ParameterLists

  # Convenience methods for common event types
  # rubocop:disable Metrics/ParameterLists
  # rubocop:disable Metrics/MethodLength
  def self.log_api_request(method:, path:, user:, status:, params: {}, response_time: nil, ip: nil, user_agent: nil,
                           request_id: nil)
    log(
      event_type: 'api_request',
      user: user,
      school: user&.school,
      data: {
        method: method,
        path: path,
        status: status,
        ip: ip,
        user_agent: user_agent,
        request_id: request_id,
        params: sanitize_params(params),
        response_time_ms: response_time
      },
      client: 'api'
    )
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/ParameterLists

  def self.log_login(user:, client: 'web')
    log(
      event_type: 'user_login',
      user: user,
      school: user&.school,
      data: {
        login_method: client
      },
      client: client
    )
  end

  def self.log_logout(user:, client: 'web')
    log(
      event_type: 'user_logout',
      user: user,
      school: user&.school,
      data: {},
      client: client
    )
  end

  def self.log_video_view(content:, user:, duration: nil, progress: nil)
    log(
      event_type: 'video_view',
      user: user,
      school: user&.school,
      data: {
        content_id: content.id,
        content_title: content.title,
        learning_module_id: content.learning_module_id,
        duration: duration,
        progress: progress
      },
      client: 'web'
    )
  end

  def self.log_quiz_start(quiz:, user:)
    log(
      event_type: 'quiz_start',
      user: user,
      school: user&.school,
      data: {
        quiz_id: quiz.id,
        quiz_title: quiz.title,
        learning_module_id: quiz.id # quiz is the learning_module itself
      },
      client: 'web'
    )
  end

  def self.log_quiz_complete(quiz_result:, user:)
    log(
      event_type: 'quiz_complete',
      user: user,
      school: user&.school,
      data: {
        quiz_result_id: quiz_result.id,
        quiz_id: quiz_result.learning_module_id,
        score: quiz_result.score,
        passed: quiz_result.passed
      },
      client: 'web'
    )
  end

  def self.log_content_access(content:, user:, action: 'view')
    log(
      event_type: "content_#{action}",
      user: user,
      school: user&.school,
      data: {
        content_id: content.id,
        content_type: content.content_type,
        content_title: content.title,
        learning_module_id: content.learning_module_id
      },
      client: 'web'
    )
  end

  # Student Video events
  def self.log_student_video_upload(video:, user:, client: 'web')
    log(
      event_type: 'student_video_upload',
      user: user,
      school: user&.school,
      data: {
        video_id: video.id,
        video_title: video.title,
        subject_id: video.subject_id,
        subject_title: video.subject_title,
        file_size_bytes: video.file_size_bytes
      },
      client: client
    )
  end

  def self.log_student_video_approve(video:, moderator:, client: 'web')
    log(
      event_type: 'student_video_approve',
      user: moderator,
      school: moderator&.school,
      data: {
        video_id: video.id,
        video_title: video.title,
        author_id: video.user_id,
        author_name: video.author_name,
        subject_id: video.subject_id
      },
      client: client
    )
  end

  def self.log_student_video_reject(video:, moderator:, reason: nil, client: 'web')
    log(
      event_type: 'student_video_reject',
      user: moderator,
      school: moderator&.school,
      data: {
        video_id: video.id,
        video_title: video.title,
        author_id: video.user_id,
        author_name: video.author_name,
        reason: reason
      },
      client: client
    )
  end

  def self.log_student_video_delete(video:, user:, client: 'web')
    log(
      event_type: 'student_video_delete',
      user: user,
      school: user&.school,
      data: {
        video_id: video.id,
        video_title: video.title,
        author_id: video.user_id,
        was_approved: video.approved?
      },
      client: client
    )
  end

  def self.log_student_video_like(video:, user:, liked:, client: 'web')
    log(
      event_type: liked ? 'student_video_like' : 'student_video_unlike',
      user: user,
      school: user&.school,
      data: {
        video_id: video.id,
        video_title: video.title,
        author_id: video.user_id,
        likes_count: video.likes_count
      },
      client: client
    )
  end

  def self.log_content_like(content:, user:, liked:, client: 'web')
    log(
      event_type: liked ? 'content_like' : 'content_unlike',
      user: user,
      school: user&.school,
      data: {
        content_id: content.id,
        content_type: content.content_type,
        content_title: content.title,
        learning_module_id: content.learning_module_id,
        likes_count: content.likes_count
      },
      client: client
    )
  end

  def self.log_student_video_youtube_upload(video:, youtube_url:, youtube_id:)
    log(
      event_type: 'student_video_youtube_upload',
      user: video.user,
      school: video.school,
      data: {
        video_id: video.id,
        video_title: video.title,
        youtube_url: youtube_url,
        youtube_id: youtube_id
      },
      client: 'system'
    )
  end

  def self.sanitize_params(params)
    # Remove sensitive data from params
    # Convert ActionController::Parameters to hash if needed
    sanitized = params.is_a?(ActionController::Parameters) ? params.to_h : params.dup
    sanitized = sanitized.stringify_keys if sanitized.respond_to?(:stringify_keys)
    # Handle both string and symbol keys
    sanitized.delete('password')
    sanitized.delete(:password)
    sanitized.delete('password_confirmation')
    sanitized.delete(:password_confirmation)
    sanitized.delete('token')
    sanitized.delete(:token)
    sanitized.delete('access_token')
    sanitized.delete(:access_token)
    sanitized.delete('refresh_token')
    sanitized.delete(:refresh_token)
    sanitized
  end
end
# rubocop:enable Metrics/ClassLength
