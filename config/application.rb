require_relative 'boot'

require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'active_storage/engine'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_mailbox/engine'
require 'action_text/engine'
require 'action_view/railtie'
require 'action_cable/engine'
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# Devise 4.9.x fix for Rails 8.x deprecation warnings
# See: lib/devise_rails8_route_patch.rb
# TODO: Remove once Devise 4.10+ is released with the fix
require_relative '../lib/devise_rails8_route_patch'
ActionDispatch::Routing::Mapper.prepend(DeviseRails8RoutePatch)

module Akademy
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
    # Ensure Sidekiq workers under `app/jobs` are eagerly loaded in production.
    config.eager_load_paths << Rails.root.join('app/jobs')
    config.time_zone = 'Europe/Warsaw'
    config.i18n.available_locales = %i[pl en]
    config.i18n.default_locale = :pl
    config.active_job.queue_adapter = :sidekiq

    config.generators do |g|
      # Don't generate system test files.
      g.system_tests = nil
      g.orm :active_record, primary_key_type: :uuid
      g.test_framework :rspec
    end

    config.autoload_paths << Rails.root.join('app/middleware')

    # Session store: Redis when Settings.redis_url set, CookieStore otherwise
    config.middleware.use ActionDispatch::Cookies
    session_key = '_akademy_session'
    if Settings.redis_url.presence
      # Use separate Redis DB for sessions (e.g. /1) so Sidekiq (often /0) is untouched
      session_redis_url = Settings.redis_url.sub(%r{/\d*\z}, '/1')
      config.session_store :redis_store,
                           servers: [session_redis_url],
                           expire_after: 7.days,
                           key: session_key,
                           threadsafe: true
    else
      config.session_store :cookie_store, key: session_key
    end
  end
end
