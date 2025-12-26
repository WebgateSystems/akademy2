require 'sidekiq'
require 'sidekiq-scheduler'
require 'sidekiq-scheduler/web'
require 'logger'

Sidekiq.configure_server do |config|
  config.redis = { url: Settings.redis_url }

  console_logger = Logger.new($stdout)
  console_logger.level = Logger::DEBUG

  # In production we typically run Sidekiq under systemd/Docker which already captures STDOUT/STDERR.
  # Avoid double-logging to the same logfile (systemd StandardOutput + Sidekiq :logfile + custom file logger).
  config.logger = console_logger

  config.on(:startup) do
    # In production, ensure all application constants (including Sidekiq jobs) are loaded.
    # This prevents NameError "uninitialized constant ..." for newly added job classes.
    Rails.application&.eager_load!

    schedule_file = 'config/sidekiq.yml'

    Sidekiq::Scheduler.reload_schedule! if File.exist?(schedule_file) && Sidekiq.server?
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: Settings.redis_url }
end
