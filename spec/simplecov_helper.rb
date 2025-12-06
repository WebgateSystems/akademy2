require 'simplecov'

# Only start SimpleCov if not already running (prevents double initialization)
unless SimpleCov.running
  SimpleCov.start do
    # Track all Ruby files in app directory
    track_files 'app/**/*.rb'

    # Filters - exclude from coverage (only infrastructure/test files)
    add_filter '/spec/'
    add_filter '/config/'
    add_filter '/db/'
    add_filter '/vendor/'
    add_filter '/lib/tasks/'
    add_filter 'app/channels/application_cable/connection.rb'
    # Exclude generated/migration files
    add_filter '/db/migrate/'
    add_filter '/db/seeds/'

    # Groups for better reporting
    add_group 'Controllers', 'app/controllers'
    add_group 'Models', 'app/models'
    add_group 'Interactors', 'app/interactors'
    add_group 'Services', 'app/services'
    add_group 'Serializers', 'app/serializers'
    add_group 'Policies', 'app/policies'
    add_group 'Forms', 'app/forms'
    add_group 'Jobs', 'app/jobs'
    add_group 'Mailers', 'app/mailers'
    add_group 'Uploaders', 'app/uploaders'

    # Output directory
    coverage_dir 'coverage'

    # Command name for merging
    command_name 'RSpec'

    # Minimum coverage threshold (can be adjusted)
    minimum_coverage(80)
  end
end
