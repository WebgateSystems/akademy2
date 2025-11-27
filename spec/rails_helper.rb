ENV['RAILS_ENV'] ||= 'test'
require 'simplecov_helper'
require 'spec_helper'
require 'json_matchers/rspec'
require 'shoulda/matchers'
require 'webmock/rspec'
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

JsonMatchers.schema_root = 'spec/support/api/schemas'

RSpec.configure do |config|
  # config.fixture_path = Rails.root.join('spec/fixtures').to_s
  config.include ApplicationTestHelper
  config.include FactoryBot::Syntax::Methods
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
end

RSpec::Matchers.define :permit do |action|
  match do |policy|
    policy.public_send("#{action}?")
  end
end
