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
gem 'devise', '~> 4.9'
gem 'devise-jwt', '~> 0.12.1'
gem 'ffaker'
gem 'image_processing', '~> 1.14'
gem 'interactor', '~> 3.0'
gem 'jsbundling-rails', '~> 1.3'
gem 'jsonapi-serializer'
gem 'jwt', '~> 2.7.1'
gem 'oj', '~> 3.16'
gem 'pry'
gem 'pundit', '~> 2.5'
gem 'rack-attack', '~> 6.7'
gem 'rqrcode', '~> 3.1'
gem 'rswag'
gem 'sidekiq', '~> 8.0'
gem 'slim-rails'
gem 'solid_cable'
gem 'solid_cache'
gem 'solid_queue'
gem 'thruster', require: false
gem 'wicked_pdf', '~> 2.8'

group :development, :test do
  gem 'bullet'
  gem 'debug', platforms: %i[mri windows], require: 'debug/prelude'
  gem 'factory_bot_rails'
  gem 'letter_opener', github: 'ryanb/letter_opener'
  gem 'rspec-rails', '~> 8.0'
end

group :test do
  gem 'json_matchers'
  gem 'rspec_junit_formatter'
  gem 'shoulda-matchers', '~> 5.0'
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
  gem 'capistrano-rails'
  gem 'capistrano-rvm'

  gem 'web-console'

  gem 'fasterer', require: false
  gem 'lefthook', require: false
  gem 'reek', require: false
  gem 'rubocop', '~> 1.64', require: false
  gem 'rubocop-factory_bot', require: false
  gem 'rubocop-rails', '~> 2.34', require: false
  gem 'rubocop-rspec_rails', require: false

  gem 'rubocop-i18n', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rspec', require: false
end
