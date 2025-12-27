# frozen_string_literal: true

module ApiRequestLogger
  extend ActiveSupport::Concern

  included do
    around_action :log_api_request, if: -> { should_log_request? }
  end

  private

  def should_log_request?
    # Skip logging for certain endpoints
    return false if request.path.include?('/api-docs')
    return false if request.path == '/api/v1/session' && request.method == 'POST' # Login is logged separately
    return false if request.path.start_with?('/api/v1/events') # Don't log events endpoint to avoid infinite loop

    true
  end

  def log_api_request
    start_time = Time.current
    yield
  ensure
    # Log all API traffic (even unauthenticated/forbidden) so the dashboard chart reflects reality.
    log_request_if_needed(start_time) if response.status < 500
  end

  def log_request_if_needed(start_time)
    response_time = ((Time.current - start_time) * 1000).round(2)
    EventLogger.log_api_request(
      method: request.method,
      path: request.path,
      user: current_user,
      status: response.status,
      params: request.params.except('controller', 'action', 'format'),
      response_time: response_time,
      ip: request.remote_ip,
      user_agent: request.user_agent,
      request_id: request.request_id
    )
  end
end
