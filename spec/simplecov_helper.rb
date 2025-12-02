require 'simplecov'

# Only start SimpleCov if not already running (prevents double initialization)
unless SimpleCov.running
  SimpleCov.start do
    # Track all Ruby files in app directory
    track_files 'app/**/*.rb'

    # Filters - exclude from coverage
    add_filter '/app/models'
    add_filter '/app/jobs'
    add_filter '/app/mailers'
    add_filter '/lib'
    add_filter 'app/channels/application_cable/connection.rb'
    add_filter 'app/dashboards'
    add_filter 'app/controllers/admin'
    add_filter '/spec/'
    add_filter '/config/'
    add_filter '/db/'
    add_filter '/vendor/'

    # Groups for better reporting
    add_group 'Controllers', 'app/controllers'
    add_group 'Interactors', 'app/interactors'
    add_group 'Services', 'app/services'
    add_group 'Serializers', 'app/serializers'
    add_group 'Policies', 'app/policies'
    add_group 'Forms', 'app/forms'

    # Merge results from multiple test runs
    merge_timeout(3600) # 1 hour

    # Output directory
    coverage_dir 'coverage'

    # Command name for merging
    command_name 'RSpec'

    minimum_coverage(80)
  end
end
