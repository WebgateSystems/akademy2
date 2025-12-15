ENV['RAILS_ENV'] ||= 'test'

# SimpleCov MUST be required and started BEFORE any application code is loaded
require 'simplecov_helper'

require 'spec_helper'
require 'json_matchers/rspec'
require 'shoulda/matchers'
require 'webmock/rspec'
require 'sidekiq/testing'
require_relative 'support/helpers/application_test_helper'

require_relative '../config/environment'

abort(_('The Rails environment is running in production mode!')) if Rails.env.production?
require 'rspec/rails'

Dir[Rails.root.join('spec/support/**/*.rb')].sort.each { |f| require f }

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

Sidekiq::Testing.fake!

JsonMatchers.schema_root = 'spec/support/api/schemas'

RSpec.configure do |config|
  # config.fixture_path = Rails.root.join('spec/fixtures').to_s
  config.include ApplicationTestHelper
  config.include FactoryBot::Syntax::Methods
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include ActiveJob::TestHelper
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  # Ensure English locale for consistent error messages in tests
  config.before do
    I18n.locale = :en
  end

  config.after do
    I18n.locale = I18n.default_locale
    # Clean up invite tokens registry after each test
    InviteTokens::Validator.clear_registry! if defined?(InviteTokens::Validator)
  end
end

RSpec::Matchers.define :permit do |action|
  match do |policy|
    policy.public_send("#{action}?")
  end
end
