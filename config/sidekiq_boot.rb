# frozen_string_literal: true

# Sidekiq boot file.
# We use this instead of relying on autoloading to avoid rare NameError issues like:
#   "uninitialized constant ProcessVideoJob"
#
# It loads the Rails environment and then eagerly requires all job files.

require_relative 'environment'

# Ensure Rails is fully loaded and all classes are available
Rails.application.eager_load!

# Explicitly load base classes first, then all jobs
require Rails.root.join('app/jobs/application_job.rb')
require Rails.root.join('app/jobs/base_sidekiq_job.rb')

Dir[Rails.root.join('app/jobs/**/*.rb')].sort.each do |path|
  # Skip already loaded base classes
  next if path.end_with?('application_job.rb', 'base_sidekiq_job.rb')

  require path
end
