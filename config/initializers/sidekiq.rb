require 'sidekiq'
require 'sidekiq-scheduler'
require 'sidekiq-scheduler/web'
require 'logger'
require_relative '../../lib/multi_logger'

Sidekiq.configure_server do |config|
  config.redis = { url: Settings.redis_url }

  file_logger = Logger.new(Rails.root.join('log/sidekiq.log'))
  file_logger.level = Logger::DEBUG

  console_logger = Logger.new($stdout)
  console_logger.level = Logger::DEBUG

  config.logger = MultiLogger.new(file_logger, console_logger)

  config.on(:startup) do
    schedule_file = 'config/sidekiq.yml'

    Sidekiq::Scheduler.reload_schedule! if File.exist?(schedule_file) && Sidekiq.server?
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: Settings.redis_url }
end
