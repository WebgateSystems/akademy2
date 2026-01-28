# frozen_string_literal: true

require 'sidekiq'
require 'sidekiq-scheduler'

redis_url = Settings.redis_url.presence || 'redis://localhost:6379/0'

# Configure Sidekiq client (for enqueueing jobs from Rails app)
Sidekiq.configure_client do |config|
  config.redis = { url: redis_url }
end

# Configure Sidekiq server (for processing jobs)
Sidekiq.configure_server do |config|
  config.redis = { url: redis_url }

  # Ensure all job classes are loaded before processing starts
  config.on(:startup) do
    Rails.application.eager_load! unless Rails.application.config.eager_load

    # Verify critical job classes are available
    %w[
      BaseSidekiqJob
      ProcessVideoJob
      SendEmailJob
      ClearRegisterFlowJob
      UploadVideoToYoutubeJob
      DeleteYoutubeVideoJob
      RollupApiRequestMetricsJob
      PurgeOldApiRequestDataJob
    ].each do |job_class|
      unless Object.const_defined?(job_class)
        Rails.logger.error "[Sidekiq] FATAL: #{job_class} not loaded!"
        raise format(_('Sidekiq startup failed: %<job_class>s not loaded'), job_class: job_class)
      end
    end

    Rails.logger.info '[Sidekiq] All job classes verified and loaded.'
  end
end
