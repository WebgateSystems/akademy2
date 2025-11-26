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

    true
  end

  def log_api_request
    start_time = Time.current
    yield
  ensure
    log_request_if_needed(start_time) if current_user && response.status < 500
  end

  def log_request_if_needed(start_time)
    response_time = ((Time.current - start_time) * 1000).round(2)
    EventLogger.log_api_request(
      method: request.method,
      path: request.path,
      user: current_user,
      status: response.status,
      params: request.params.except('controller', 'action', 'format'),
      response_time: response_time
    )
  end
end
