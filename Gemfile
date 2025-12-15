source 'https://rubygems.org'

gem 'config'
gem 'pg', '~> 1.1'
gem 'propshaft'
gem 'puma', '>= 7.1'
gem 'rails', '~> 8.1.1', '>= 8.1.1'

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem 'bootsnap', require: false
gem 'carrierwave', '~> 3.0'
gem 'cssbundling-rails', '~> 1.4'

# Video processing
gem 'devise', '~> 4.9'
gem 'devise-jwt', '~> 0.12.1'
gem 'dry-validation'
gem 'elasticsearch', '~> 8.0' # Elasticsearch client for searchkick
gem 'ffaker'
gem 'image_processing', '~> 1.14'
gem 'interactor', '~> 3.0'
gem 'jsbundling-rails', '~> 1.3'
gem 'jsonapi-serializer'
gem 'jwt', '~> 3.1.2'
gem 'mjml-rails', '~> 4.12'
gem 'mrml', '~> 1.4' # Rust MJML parser - faster, no Node.js required
gem 'oj', '~> 3.16'
gem 'pry'
gem 'pundit', '~> 2.5'
gem 'rack-attack', '~> 6.7'
gem 'rqrcode', '~> 3.1'
gem 'rswag'
gem 'searchkick' # Elasticsearch integration for full-text search
gem 'sidekiq', '~> 8.0'
gem 'sidekiq-cron', '~> 1.0'
gem 'sidekiq-scheduler'
gem 'slim-rails'
gem 'solid_cable'
gem 'solid_cache'
gem 'solid_queue'
gem 'streamio-ffmpeg', '~> 3.0'
gem 'thruster', require: false
gem 'twilio-ruby'
gem 'wicked_pdf', '~> 2.8'

gem 'combine_pdf'
gem 'csv'
gem 'google-api-client', '~> 0.53.0'
gem 'prawn'
gem 'prawn-table'

group :development, :test do
  gem 'bullet'
  gem 'debug', platforms: %i[mri windows], require: 'debug/prelude'
  gem 'factory_bot_rails'
  gem 'letter_opener', github: 'ryanb/letter_opener'
  gem 'rails-controller-testing'
  gem 'rspec-rails', '~> 8.0'
end

group :production do
  gem 'bcrypt_pbkdf', '~> 1.0'
  gem 'ed25519', '~> 1.2'
end

group :test do
  gem 'database_cleaner-active_record'
  gem 'json_matchers'
  gem 'rspec_junit_formatter'
  gem 'shoulda-matchers', '~> 7.0'
  gem 'simplecov', require: false
  gem 'webmock'
end

group :development do
  gem 'brakeman', require: false
  gem 'bundle-audit', require: false

  # Deploy with Capistrano
  gem 'bot-notifier', '~> 3.1.0', github: 'WebgateSystems/bot-notifier', require: false
  gem 'cape'
  gem 'capistrano3-puma', github: 'seuros/capistrano-puma'
  gem 'capistrano-hook', require: false
  gem 'capistrano-nvm', require: false
  gem 'capistrano-rails'
  gem 'capistrano-rvm'

  gem 'fasterer', require: false
  gem 'i18n-tasks'
  gem 'reek', require: false
  gem 'rubocop', '~> 1.64', require: false
  gem 'rubocop-factory_bot', require: false
  gem 'rubocop-i18n', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', '~> 2.25', require: false
  gem 'rubocop-rspec', require: false
  gem 'rubocop-rspec_rails', require: false

  gem 'web-console'
end
