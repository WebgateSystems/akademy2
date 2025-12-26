# frozen_string_literal: true

# Sidekiq boot file.
# We use this instead of relying on autoloading to avoid rare NameError issues like:
#   "uninitialized constant ProcessVideoJob"
#
# It loads the Rails environment and then eagerly requires all job files.

require_relative 'environment'

Dir[Rails.root.join('app/jobs/**/*.rb')].sort.each { |path| require path }
