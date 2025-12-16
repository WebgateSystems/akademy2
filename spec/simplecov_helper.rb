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
    add_filter 'lib'
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
    minimum_coverage(90)

    # Update coverage badge in README after tests complete
    at_exit do
      result = SimpleCov.result

      # generate HTML report
      result.format!
      coverage = SimpleCov.result.covered_percent.round(1)
      color = case coverage
              when 90.. then 'brightgreen'
              when 80.. then 'green'
              when 70.. then 'yellow'
              when 60.. then 'orange'
              else 'red'
              end

      badge_url = "https://img.shields.io/badge/coverage-#{coverage}%25-#{color}"
      badge_markdown = "![Coverage](#{badge_url})"

      %w[README.md README.en.md README.ua.md].each do |readme|
        path = File.join(SimpleCov.root, readme)
        next unless File.exist?(path)

        content = File.read(path)
        updated = content.gsub(/!\[Coverage\]\([^)]*\)/, badge_markdown)
        File.write(path, updated) if content != updated
      end

      puts "\n📊 Coverage: #{coverage}% - Badge updated in README"
    end
  end
end
